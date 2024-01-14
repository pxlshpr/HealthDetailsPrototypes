import SwiftUI
import HealthKit

extension HealthProvider {
    //TODO: Consider a rewrite
    /// [x] First add the source data into HealthKitMeasurement so that we can filter out what's form Apple or us
    /// [x] Rename to Sync with everything or something
    static func syncWithHealthKitAndRecalculateAllDays() async {
        
        var days = await fetchAllDaysFromDocuments()
        let initialDays = days

        let start = CFAbsoluteTimeGetCurrent()
        
        /// Fetch all HealthKit weight samples from start of log (since we're not interested in any before that)
        let startDate = await fetchBackendLogStartDate()
        
        let settingsProvider = fetchSettingsFromDocuments()
        
        /// First, fetch whatever isSynced is turned on for (weight, height, LBM)—fetch everything from the first Day's date onwards
        let weightSamples: [HKQuantitySample]? = if settingsProvider.isHealthKitSyncing(.weight) {
            await HealthStore.weightMeasurements(from: startDate)
        } else {
            nil
        }
        let leanBodyMassSamples: [HKQuantitySample]? = if settingsProvider.isHealthKitSyncing(.leanBodyMass) {
            await HealthStore.leanBodyMassMeasurements(from: startDate)
        } else {
            nil
        }
        let heightSamples: [HKQuantitySample]? = if settingsProvider.isHealthKitSyncing(.height) {
            await HealthStore.heightMeasurements(from: startDate)
        } else {
            nil
        }
        
        /// Special case with height – if we have do not have any data within our app's timeframe—grab the latest height available and save it
        if (heightSamples == nil || heightSamples?.isEmpty == true), let latestHeight = await HealthStore.heightMeasurements().suffix(1).first
        {
            await saveHealthKitHeightMeasurement(latestHeight)
        }
        
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

        await recalculate(days, initialDays: initialDays, start: start)
    }
}

extension HealthProvider {
    static func recalculate(_ days: [Day], initialDays: [Day]? = nil, start: CFAbsoluteTime? = nil) async {
        
        let start = start ?? CFAbsoluteTimeGetCurrent()
        let initialDays = initialDays ?? days

        for i in days.indices {
            
            let day = days[i]

            if days[i] != initialDays[i] {
                print("Saving \(days[i].date.shortDateString)")
                saveDayInDocuments(days[i])
            } else {
                
            }
        }
        
        print("recalculate ended after: \(CFAbsoluteTimeGetCurrent()-start)s")

        //TODO: We need to:
        /// [ ] Go through each Day in order
        /// [ ] Get the HealthDetails
        /// [ ] Create a HealthProvider for it (which in turn fetches the latest health details)
        /// [ ] ~~Get the HealthProvider to fetch HealthKit values~~
        /// [ ] Now based on the Daily Value Type's, re-set the values for measurements
        /// [ ] Recalculate LBM, fat percentage
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
            let days = await fetchAllDaysFromDocuments()
            await recalculate(days)
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
