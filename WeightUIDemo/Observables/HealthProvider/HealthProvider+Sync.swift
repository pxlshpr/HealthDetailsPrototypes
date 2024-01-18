import SwiftUI
import HealthKit

extension HealthProvider {

    static func syncWithHealthKitAndRecalculateAllDays() async throws {

        let start = CFAbsoluteTimeGetCurrent()
        
        /// Fetch all HealthKit weight samples from start of log (since we're not interested in any before that)
        let logStartDate = await DayProvider.fetchBackendLogStartDate()
        var daysStartDate = logStartDate
        
        let settings = await fetchSettingsFromDocuments()
        
        /// First, fetch whatever isSynced is turned on for (weight, height, LBM)—fetch everything from the first Day's date onwards
        var weightSamples: [HKQuantitySample]? = if settings.isHealthKitSyncing(.weight) {
            await HealthStore.weightSamples(from: logStartDate)
        } else {
            nil
        }
        var leanBodyMassSamples: [HKQuantitySample]? = if settings.isHealthKitSyncing(.leanBodyMass) {
            await HealthStore.leanBodyMassSamples(from: logStartDate)
        } else {
            nil
        }
        var fatPercentageSamples: [HKQuantitySample]? = if settings.isHealthKitSyncing(.fatPercentage) {
            await HealthStore.fatPercentageSamples(from: logStartDate)
        } else {
            nil
        }
        var heightSamples: [HKQuantitySample]? = if settings.isHealthKitSyncing(.height) {
            await HealthStore.heightSamples(from: logStartDate)
        } else {
            nil
        }
        
        /// If we have do not have any data within our app's timeframe—grab the latest available and create a Day and save it

        if heightSamples.isEmptyOrNil,
            let sample = await HealthStore.mostRecentSample(for: .height)
        {
            if sample.startDate < daysStartDate { daysStartDate = sample.startDate }
            /// This is crucial, otherwise it not being included in the array has the value
            heightSamples = [sample]
            try await saveHealthKitSample(sample, for: .height)
        }
        if weightSamples.isEmptyOrNil, 
            let sample = await HealthStore.mostRecentSample(for: .weight)
        {
            if sample.startDate < daysStartDate { daysStartDate = sample.startDate }
            weightSamples = [sample]
            try await saveHealthKitSample(sample, for: .weight)
        }
        if leanBodyMassSamples.isEmptyOrNil, 
            let sample = await HealthStore.mostRecentSample(for: .leanBodyMass)
        {
            if sample.startDate < daysStartDate { daysStartDate = sample.startDate }
            leanBodyMassSamples = [sample]
            try await saveHealthKitSample(sample, for: .leanBodyMass)
        }
        if fatPercentageSamples.isEmptyOrNil,
           let sample = await HealthStore.mostRecentSample(for: .fatPercentage)
        {
            if sample.startDate < daysStartDate { daysStartDate = sample.startDate }
            fatPercentageSamples = [sample]
            try await saveHealthKitSample(sample, for: .fatPercentage)
        }

        var days = await fetchAllDaysFromDocuments(
            from: daysStartDate,
            createIfNotExisting: false
        )
        let initialDays = days
        
        var toDelete: [HKQuantitySample] = []
        var toExport: [any Measurable] = []
        
        let startR = CFAbsoluteTimeGetCurrent()
        let restingEnergyStats = await HealthStore.dailyStatistics(
            for: .basalEnergyBurned,
            from: logStartDate,
            to: Date.now
        )
        print("Getting all RestingEnergy took: \(CFAbsoluteTimeGetCurrent()-startR)s")

        let startA = CFAbsoluteTimeGetCurrent()
        let activeEnergyStats = await HealthStore.dailyStatistics(
            for: .activeEnergyBurned,
            from: logStartDate,
            to: Date.now
        )
        print("Getting all ActiveEnergy took: \(CFAbsoluteTimeGetCurrent()-startA)s")

        let startD = CFAbsoluteTimeGetCurrent()
        let dietaryEnergyStats = await HealthStore.dailyStatistics(
            for: .dietaryEnergyConsumed,
            from: logStartDate,
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
                    toExport: &toExport,
                    settings: settings
                )
            }

            if let heightSamples {
                days[i].healthDetails.height.processHealthKitSamples(
                    heightSamples,
                    for: date,
                    toDelete: &toDelete,
                    toExport: &toExport,
                    settings: settings
                )
            }

            if let leanBodyMassSamples {
                days[i].healthDetails.leanBodyMass.processHealthKitSamples(
                    leanBodyMassSamples,
                    for: date,
                    toDelete: &toDelete, 
                    toExport: &toExport,
                    settings: settings
                )
            }

            if let fatPercentageSamples {
                days[i].healthDetails.fatPercentage.processHealthKitSamples(
                    fatPercentageSamples,
                    for: day.date,
                    toDelete: &toDelete,
                    toExport: &toExport,
                    settings: settings
                )
            }

            /// If the day has DietaryEnergyPointSource, RestingEnergySource or ActivieEnergySource as .healthKit, fetch them and set them
            await days[i].dietaryEnergyPoint?
                .mock_fetchFromHealthKitIfNeeded(for: day, using: dietaryEnergyStats)
            
            await days[i].healthDetails.maintenance.estimate.restingEnergy
                .mock_fetchFromHealthKitIfNeeded(for: date, using: restingEnergyStats)

            await days[i].healthDetails.maintenance.estimate.activeEnergy
                .mock_fetchFromHealthKitIfNeeded(for: date, using: activeEnergyStats)
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

        try await DayProvider.recalculateAllDays(
            days,
            initialDays: initialDays,
            start: start,
            cancellable: false /// Disallow the recalculation to be cancellable as the sync takes some time and any new recalculation
        )
    }
}

extension HealthProvider {
    func setDailyValueType(for healthDetail: HealthDetail, to type: DailyValueType) {
        settingsProvider.settings.setDailyValueType(type, for: healthDetail)
        settingsProvider.save()
        /// Calling this to only recalculate as no changes were made to save. But we want to make sure there is only one of this occurring at any given time.
        save()
    }
    
    func setHealthKitSyncing(for healthDetail: HealthDetail, to isOn: Bool) {
        settingsProvider.settings.setHealthKitSyncing(for: healthDetail, to: isOn)
        settingsProvider.save()
        if isOn {
//            resyncAndRecalculateAllDays()
        }
    }
}

extension HealthKitSyncable {
    mutating func processHealthKitSamples(
        _ samples: [HKQuantitySample],
        for date: Date,
        toDelete: inout [HKQuantitySample],
        toExport: inout [any Measurable],
        settings: Settings
    ) {
        let samples = samples
            .filter { $0.date.startOfDay == date.startOfDay }
            .removingSamplesWithTheSameValueAtTheSameTime(with: MeasurementType.healthKitUnit)

        removeHealthKitQuantitySamples(notPresentIn: samples.notOurs)
        addNewHealthKitQuantitySamples(from: samples.notOurs)
        toDelete.append(contentsOf: samples.ours.notPresent(in: measurements))
        toExport.append(contentsOf: measurements.nonHealthKitMeasurements.notPresent(in: samples.ours))
        setDailyValue(for: settings.dailyValueType(for: self.healthDetail))
    }
}

extension Array where Element: HKQuantitySample {
    func removingSamplesWithTheSameValueAtTheSameTime(with unit: HKUnit) -> [HKQuantitySample] {
        var array: [HKQuantitySample] = []

        for sample in self {
            /// If the array already contains a value at the same *minute* as this element with the same value (to 1 decimal place)
            if let index = array.firstIndex(where: { $0.hasSameValueAndTime(as: sample, with: unit) }) {
                /// Then replace it with this, if the UUID alphabetically precedes the existing one's UUID
                if sample.shouldBePicked(insteadOf: array[index]) {
                    array[index] = sample
                }
                /// Otherwise ignore it
            } else {
                array.append(sample)
            }
        }
        return array
    }
}

extension HKQuantitySample {
    func hasSameValueAndTime(as sample: HKQuantitySample, with unit: HKUnit) -> Bool {
        quantity.doubleValue(for: unit).rounded(toPlaces: 1) == sample.quantity.doubleValue(for: unit).rounded(toPlaces: 1)
        && startDate.equalsIgnoringSeconds(sample.startDate)
    }
    
    func shouldBePicked(insteadOf sample: HKQuantitySample) -> Bool {
        uuid.uuidString < sample.uuid.uuidString
    }
}
