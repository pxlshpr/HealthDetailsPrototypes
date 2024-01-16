import SwiftUI
import HealthKit

extension HealthProvider {
    //TODO: Consider a rewrite
    /// [x] First add the source data into HealthKitMeasurement so that we can filter out what's form Apple or us
    /// [x] Rename to Sync with everything or something
    static func syncWithHealthKitAndRecalculateAllDays() async {

        let start = CFAbsoluteTimeGetCurrent()
        
        /// Fetch all HealthKit weight samples from start of log (since we're not interested in any before that)
        let startDate = await fetchBackendLogStartDate()
        
        let settings = SettingsProvider.shared.settings
        
        /// First, fetch whatever isSynced is turned on for (weight, height, LBM)—fetch everything from the first Day's date onwards
        let weightSamples: [HKQuantitySample]? = if settings.isHealthKitSyncing(.weight) {
            await HealthStore.weightMeasurements(from: startDate)
        } else {
            nil
        }
        let leanBodyMassSamples: [HKQuantitySample]? = if settings.isHealthKitSyncing(.leanBodyMass) {
            await HealthStore.leanBodyMassMeasurements(from: startDate)
        } else {
            nil
        }
        let heightSamples: [HKQuantitySample]? = if settings.isHealthKitSyncing(.height) {
            await HealthStore.heightMeasurements(from: startDate)
        } else {
            nil
        }
        
        /// Special case with height – if we have do not have any data within our app's timeframe—grab the latest height available and save it
        if (heightSamples == nil || heightSamples?.isEmpty == true), let latestHeight = await HealthStore.heightMeasurements().suffix(1).first
        {
            await saveHealthKitHeightMeasurement(latestHeight)
        }
        
        var days = await fetchAllDaysFromDocuments(
            from: DaysStartDate,
            createIfNotExisting: false
        )
        let initialDays = days
        
        var toDelete: [HKQuantitySample] = []
        var toExport: [any Measurable] = []
        
        let startR = CFAbsoluteTimeGetCurrent()
        let restingEnergyStats = await HealthStore.dailyStatistics(
            for: .basalEnergyBurned,
            from: LogStartDate,
            to: Date.now
        )
        print("Getting all RestingEnergy took: \(CFAbsoluteTimeGetCurrent()-startR)s")

        let startA = CFAbsoluteTimeGetCurrent()
        let activeEnergyStats = await HealthStore.dailyStatistics(
            for: .activeEnergyBurned,
            from: LogStartDate,
            to: Date.now
        )
        print("Getting all ActiveEnergy took: \(CFAbsoluteTimeGetCurrent()-startA)s")

        let startD = CFAbsoluteTimeGetCurrent()
        let dietaryEnergyStats = await HealthStore.dailyStatistics(
            for: .dietaryEnergyConsumed,
            from: LogStartDate,
            to: Date.now
        )
        print("Getting all DietaryEnergy took: \(CFAbsoluteTimeGetCurrent()-startD)s")
        
        /// Go through each Day
        for i in days.indices {

            let day = days[i]
            let date = day.date

//            print("Syncing HealthKit values for: \(day.date.shortDateString)")

            if let weightSamples {
                days[i].healthDetails.weight.processHealthKitSamples(
                    weightSamples, 
                    for: date,
                    toDelete: &toDelete,
                    toExport: &toExport
                )
            }

            if let heightSamples {
                days[i].healthDetails.height.processHealthKitSamples(
                    heightSamples,
                    for: date,
                    toDelete: &toDelete,
                    toExport: &toExport
                )
            }

            if let leanBodyMassSamples {
                days[i].healthDetails.leanBodyMass.processHealthKitSamples(
                    leanBodyMassSamples,
                    for: date,
                    toDelete: &toDelete, 
                    toExport: &toExport
                )
            }

//            if let fatPercentageSamples {
//                days[i].healthDetails.fatPercentage.processHealthKitSamples(
//                    fatPercentageSamples,
//                    for: day.date,
//                    toDelete: &toDelete,
//                    toExport: &toExport
//                )
//            }

            /// If the day has DietaryEnergyPointSource, RestingEnergySource or ActivieEnergySource as .healthKit, fetch them and set them
            let start = CFAbsoluteTimeGetCurrent()
            await days[i].dietaryEnergyPoint?
                .mock_fetchFromHealthKitIfNeeded(for: day, using: dietaryEnergyStats)
            
            await days[i].healthDetails.maintenance.estimate.restingEnergy
                .mock_fetchFromHealthKitIfNeeded(for: date, using: restingEnergyStats)

            await days[i].healthDetails.maintenance.estimate.activeEnergy
                .mock_fetchFromHealthKitIfNeeded(for: date, using: activeEnergyStats)

            print("\(day.date.dateString) – Fetching HealthKit values took \(CFAbsoluteTimeGetCurrent()-start)s")
        }
        
//        print("We have: \(toDelete.count) to delete")
//        print("We have: \(toExport.count) to export")
        
        /// Once we're done, go ahead and delete all the measurements we put aside to be deleted
        if !toDelete.isEmpty {
            await HealthStore.deleteMeasurements(toDelete)
        }

        /// Also export all the measurements we put aside
        if !toExport.isEmpty {
            await HealthStore.saveMeasurements(toExport)
        }

        await recalculateAllDays(days, initialDays: initialDays, start: start)
    }
}

extension HealthDetails {
    mutating func recalculateDailyValues(using settings: Settings) {
        height.setDailyValue(for: settings.dailyValueType(for: .height))
        weight.setDailyValue(for: settings.dailyValueType(for: .weight))
        leanBodyMass.setDailyValue(for: settings.dailyValueType(for: .leanBodyMass))
//        healthDetails.fatPercentage.setDailyValue(for: settings.dailyValueType(for: .fatPercentage))
    }
    
    mutating func recalculateLeanBodyMass() {
        
    }
}

extension HealthDetails.LeanBodyMass {
    func recalculate() {
        
    }
}
extension HealthProvider {
    func recalculate() async {
        let settings = settingsProvider.settings

        /// [ ] Recalculate LBM, fat percentage

        healthDetails.recalculateDailyValues(using: settings)

        /// [ ] Recalculate resting energy
        /// [ ] Recalculate active energy
        /// [ ] For each DietaryEnergyPoint in adaptive, re-fetch if either log, or AppleHealth
        /// [ ] Recalculate DietaryEnergy
        /// [ ] If WeightChange is .usingPoints, either fetch each weight or fetch the moving average components and calculate the average
        /// [ ] Reclaculate Adaptive
        /// [ ] Recalculate Maintenance based on toggle + fallback thing
        /// [ ] TBD: Re-assign RDA values
        /// [ ] TBD: Recalculate the plans for the Day as HealthDetails have changed
    }
    
    static func recalculateAllDays(_ days: [Day], initialDays: [Day]? = nil, start: CFAbsoluteTime? = nil) async {
        
        var days = days
        let start = start ?? CFAbsoluteTimeGetCurrent()
        let initialDays = initialDays ?? days

        var latest: [HealthDetail: DatedHealthData] = [:]
        for (index, day) in days.enumerated() {
            
            var day = day
            
            /// [ ] Create a HealthProvider for it (which in turn fetches the latest health details)
            let settingsProvider = SettingsProvider.shared
            let healthProvider = HealthProvider(
                healthDetails: day.healthDetails,
                settingsProvider: settingsProvider
            )
            
            var start = CFAbsoluteTimeGetCurrent()
//            day.healthDetails.populateLatestDict(&latest)
            latest.fillInHealthDetails(day.healthDetails)
            print("  populateLatestDict took: \(CFAbsoluteTimeGetCurrent()-start)s")

            start = CFAbsoluteTimeGetCurrent()
            healthProvider.setLatest(latest)
            print("  setLatest took: \(CFAbsoluteTimeGetCurrent()-start)s")

            start = CFAbsoluteTimeGetCurrent()
            await healthProvider.recalculate()
            print("  recalculate took: \(CFAbsoluteTimeGetCurrent()-start)s")

            day.healthDetails = healthProvider.healthDetails
            
            if day != initialDays[index] {
                print("Saving \(day.date.shortDateString)")
                saveDayInDocuments(day)
            } else {
                print("Not Saving \(day.date.shortDateString)")
            }
        }
        
        print("recalculateAllDays ended after: \(CFAbsoluteTimeGetCurrent()-start)s")
    }
}

extension HealthProvider {
    func setDailyValueType(for healthDetail: HealthDetail, to type: DailyValueType) {
        settingsProvider.settings.setDailyValueType(type, for: healthDetail)
        settingsProvider.save()
        Self.recalculateAllDays()
    }
    
    func setHealthKitSyncing(for healthDetail: HealthDetail, to isOn: Bool) {
        settingsProvider.settings.setHealthKitSyncing(for: healthDetail, to: isOn)
        settingsProvider.save()
        if isOn {
//            resyncAndRecalculateAllDays()
        }
    }
    
    static func recalculateAllDays() {
        Task {
            let days = await fetchAllDaysFromDocuments(
                from: LogStartDate,
                createIfNotExisting: false
            )
            await recalculateAllDays(days)
        }
    }
}

extension HealthKitSyncable {
    mutating func processHealthKitSamples(
        _ samples: [HKQuantitySample],
        for date: Date,
        toDelete: inout [HKQuantitySample],
        toExport: inout [any Measurable]
    ) {
        let samples = samples.filter { $0.date.startOfDay == date.startOfDay }
        removeHealthKitQuantitySamples(notPresentIn: samples.notOurs)
        addNewHealthKitQuantitySamples(from: samples.notOurs)
        toDelete.append(contentsOf: samples.ours.notPresent(in: measurements))
        toExport.append(contentsOf: measurements.nonHealthKitMeasurements.notPresent(in: samples.ours))
    }
}
