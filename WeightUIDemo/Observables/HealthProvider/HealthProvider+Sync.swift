import SwiftUI
import HealthKit

extension HealthProvider {
    
    static func syncWithHealthKitAndRecalculateAllDays() async throws {
        print("🔄 syncWithHealthKitAndRecalculateAllDays() started...")

        let start = CFAbsoluteTimeGetCurrent()

        let settings = await fetchSettingsFromDocuments()

        /// Fetch all HealthKit weight samples from start of log (since we're not interested in any before that)
        let logStartDate = await DayProvider.fetchBackendLogStartDate()
        var daysStartDate = logStartDate
        
        var samples = try await samples(from: logStartDate, settings: settings)
        try await fetchMostRecentSamplesForEmptyQuantityTypes(
            samples: &samples,
            daysStartDate: &daysStartDate
        )
        
        let earliestDateForDietaryEnergyPoints = logStartDate.earliestDateForDietaryEnergyPoints

        let stats = await stats(from: earliestDateForDietaryEnergyPoints)
        
        if let dietaryEnergyStats = stats[.dietaryEnergy] {
            await updatePreLogDietaryEnergy(
                logStartDate: logStartDate,
                stats: dietaryEnergyStats
            )
        }
        
        var days = await fetchAllDaysFromDocuments(
            from: daysStartDate,
            createIfNotExisting: false
        )
        let initialDays = days
        
        var toDelete: [HKQuantitySample] = []
        var toExport: [any Measurable] = []

        await syncAndFetchAllDetails(
            days: &days,
            samples: samples,
            stats: stats,
            toDelete: &toDelete,
            toExport: &toExport,
            settings: settings
        )
        
        /// Once we're done, go ahead and delete all the measurements we put aside to be deleted
        if !toDelete.isEmpty {
            await HealthStore.deleteMeasurements(toDelete)
        }

        /// Also export all the measurements we put aside
        if !toExport.isEmpty {
            await HealthStore.saveMeasurements(toExport)
        }

        try await DayProvider.recalculateAllDays(
            days,
            initialDays: initialDays,
            syncStart: start,
            cancellable: false /// Disallow the recalculation to be cancellable as the sync takes some time and any new recalculation
        )
    }
}

//MARK: - Helpers

extension HealthProvider {
    
    static func samples(from date: Date, settings: Settings) async throws -> [QuantityType : [HKQuantitySample]] {
        var dict: [QuantityType : [HKQuantitySample]] = [:]
        for quantityType in QuantityType.syncedTypes {
            guard let healthDetail = quantityType.healthDetail,
                  settings.isHealthKitSyncing(healthDetail) else { continue }
            dict[quantityType] = await HealthStore.samples(for: quantityType, from: date)
        }
        return dict
    }
    
    static func fetchMostRecentSamplesForEmptyQuantityTypes(
        samples: inout [QuantityType : [HKQuantitySample]],
        daysStartDate: inout Date
    ) async throws {
        for quantityType in QuantityType.syncedTypes {
            /// Only do this if we don't have any samples for this quantity type
            guard
                !samples.keys.contains(quantityType)
                || samples[quantityType]?.isEmpty == true
            else {
                continue
            }
            
            /// Only continue if we there is a sample available for this type
            guard let latestSample = await HealthStore.mostRecentSample(for: quantityType) else {
                continue
            }
            
            if latestSample.startDate < daysStartDate {
                daysStartDate = latestSample.startDate
            }
            
            samples[quantityType] = [latestSample]
            try await saveHealthKitSample(latestSample, for: quantityType)
        }
    }
    
    static func stats(from startDate: Date) async -> [QuantityType : HKStatisticsCollection] {
        let start = CFAbsoluteTimeGetCurrent()
        print("Getting all stats...")
        var dict: [QuantityType : HKStatisticsCollection] = [:]
        for quantityType in QuantityType.fetchedTypes {
            dict[quantityType] = await HealthStore.dailyStatistics(
                for: quantityType.healthKitTypeIdentifier,
                from: startDate,
                to: Date.now
            )
        }
        print("...took: \(CFAbsoluteTimeGetCurrent()-start)s")
        return dict
    }
    
    static func updatePreLogDietaryEnergy(
        logStartDate: Date,
        stats: HKStatisticsCollection
    ) async {
        var start = CFAbsoluteTimeGetCurrent()

        let startDate = logStartDate.earliestDateForDietaryEnergyPoints

        print("Getting all DietaryEnergy took: \(CFAbsoluteTimeGetCurrent()-start)s")
        print("Fetching or Creating all days for dietary starting from: \(startDate.shortDateString)")
        start = CFAbsoluteTimeGetCurrent()
        var days = await fetchAllDaysFromDocuments(
            from: startDate,
            to: logStartDate.moveDayBy(-1),
            createIfNotExisting: true
        )
        print("Took: \(CFAbsoluteTimeGetCurrent()-start)s")
        print("Fetching dietary energy point from HealthKit for all those days")

        start = CFAbsoluteTimeGetCurrent()
        for (date, day) in days {
            let initialDay = day
            /// If the point doesn't exist, create it
            if day.dietaryEnergyPoint == nil {
                if let kcal = await HealthStore.dietaryEnergyTotalInKcal(
                    for: day.date,
                    using: stats
                ) {
                    days[date]?.dietaryEnergyPoint = .init(
                        date: day.date,
                        kcal: kcal,
                        source: .healthKit
                    )
                } else {
                    days[date]?.dietaryEnergyPoint = .init(
                        date: day.date,
                        source: .notCounted
                    )
                }
            } else {
                await days[date]?.dietaryEnergyPoint?.fetchFromHealthKitIfNeeded(
                    day: day,
                    using: stats
                )
            }
            
            if let updatedDay = days[date], updatedDay != initialDay {
                await saveDayInDocuments(updatedDay)
            }
        }
        print("Took: \(CFAbsoluteTimeGetCurrent()-start)s")
    }
    
    static func syncAndFetchAllDetails(
        days: inout [Date : Day],
        samples: [QuantityType : [HKQuantitySample]],
        stats: [QuantityType : HKStatisticsCollection],
        toDelete: inout [HKQuantitySample],
        toExport: inout [any Measurable],
        settings: Settings
    ) async {
        for date in days.keys {
            
            for quantityType in QuantityType.syncedTypes {
                guard let samples = samples[quantityType] else { continue }
                days[date]?.healthDetails.syncWithHealthKit(
                    quantityType: quantityType,
                    samples: samples,
                    toDelete: &toDelete,
                    toExport: &toExport,
                    settings: settings
                )
            }
            
            for quantityType in QuantityType.fetchedTypes {
                guard let stats = stats[quantityType] else { continue }
                await days[date]?.fetchFromHealthKitIfNeeded(
                    quantityType: quantityType,
                    using: stats
                )
            }
        }
    }
}
