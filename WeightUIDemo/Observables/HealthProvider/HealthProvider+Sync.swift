import SwiftUI
import HealthKit

extension HealthProvider {
    //TODO: Consider a rewrite
    /// [x] First add the source data into HealthKitMeasurement so that we can filter out what's form Apple or us
    /// [x] Rename to Sync with everything or something
    static func syncWithHealthKitAndRecalculateAllDays() async throws {

        let start = CFAbsoluteTimeGetCurrent()
        
        /// Fetch all HealthKit weight samples from start of log (since we're not interested in any before that)
        let logStartDate = await fetchBackendLogStartDate()
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
            let start = CFAbsoluteTimeGetCurrent()
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

        try await recalculateAllDays(days, initialDays: initialDays, start: start)
    }
}

extension HealthDetails {
    mutating func recalculateDailyValues(using settings: Settings) {
        height.setDailyValue(for: settings.dailyValueType(for: .height))
        weight.setDailyValue(for: settings.dailyValueType(for: .weight))
        leanBodyMass.setDailyValue(for: settings.dailyValueType(for: .leanBodyMass))
        fatPercentage.setDailyValue(for: settings.dailyValueType(for: .fatPercentage))
    }
    
    mutating func recalculateLeanBodyMass() {
        
    }
    
    mutating func convertLeanBodyMassesToFatPercentages() {
        /// Remove all the previous converted fat percentages
        fatPercentage.measurements.removeAll(where: { $0.isConvertedFromLeanBodyMass })

        /// See if we sitll have a weight available before continuing
        guard let currentOrLatestWeightInKg else { return }
        
        /// Now convert the measurements and add them
        let convertedMeasurements: [FatPercentageMeasurement] = leanBodyMass
            .measurements
            .nonConverted
            .compactMap
        { measurement in

            /// Detect already converted values by checking if its HealthKit, and if so seeing if there is a counterpart at the same minute as this value that’s also HealthKit
            if measurement.isHealthKitCounterpartToAMeasurement(in: fatPercentage) {
                return nil
            }

            return FatPercentageMeasurement(
                date: measurement.date,
                percent: calculateFatPercentage(
                    leanBodyMassInKg: measurement.leanBodyMassInKg,
                    weightInKg: currentOrLatestWeightInKg
                ),
                source: measurement.source,
                isConvertedFromLeanBodyMass: true
            )
        }
        fatPercentage.measurements.append(contentsOf: convertedMeasurements)
    }
    
    mutating func convertFatPercentagesToLeanBodyMasses() {
        /// Remove all the previous converted lean body masses
        leanBodyMass.measurements.removeAll(where: { $0.isConvertedFromFatPercentage })

        /// See if we sitll have a weight available before continuing
        guard let currentOrLatestWeightInKg else { return }
        
        /// Now convert the measurements and add them
        let convertedMeasurements: [LeanBodyMassMeasurement] = fatPercentage
            .measurements
            .nonConverted
            .compactMap
        { measurement in

            /// Detect already converted values by checking if its HealthKit, and if so seeing if there is a counterpart at the same minute as this value that’s also HealthKit
            if measurement.isHealthKitCounterpartToAMeasurement(in: leanBodyMass) {
                return nil
            }

            return LeanBodyMassMeasurement(
                date: measurement.date,
                leanBodyMassInKg: calculateLeanBodyMass(
                    fatPercentage: measurement.percent,
                    weightInKg: currentOrLatestWeightInKg),
                source: measurement.source,
                isConvertedFromFatPercentage: true
            )
        }
        leanBodyMass.measurements.append(contentsOf: convertedMeasurements)
    }
}

extension HealthDetails.LeanBodyMass {
    func recalculate() {
        
    }
}

extension HealthProvider {
    
    func recalculate() async {
        let settings = settingsProvider.settings

        /// [ ] Recalculate LBM, fat percentage based on equations and based on each other (simply recreate these if we have a weight for the day, otherwise removing them)
        healthDetails.convertLeanBodyMassesToFatPercentages()
        healthDetails.convertFatPercentagesToLeanBodyMasses()
        
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
    
    static func recalculateAllDays(
        _ days: [Day],
        initialDays: [Day]? = nil,
        start: CFAbsoluteTime? = nil
    ) async throws {
        
        let start = start ?? CFAbsoluteTimeGetCurrent()
        let initialDays = initialDays ?? days

        var latestHealthDetails: [HealthDetail: DatedHealthData] = [:]
        
        let settings = await fetchSettingsFromDocuments()
        let settingsProvider = SettingsProvider(settings: settings)

        try Task.checkCancellation()

        for (index, day) in days.enumerated() {
            
            var day = day
            
            /// [ ] Create a HealthProvider for it (which in turn fetches the latest health details)
            let healthProvider = HealthProvider(
                healthDetails: day.healthDetails,
                settingsProvider: settingsProvider
            )
            
            latestHealthDetails.setHealthDetails(from: day.healthDetails)
            healthProvider.healthDetails.setLatestHealthDetails(latestHealthDetails)
            await healthProvider.recalculate()

            day.healthDetails = healthProvider.healthDetails

            try Task.checkCancellation()

            if day != initialDays[index] {
                await saveDayInDocuments(day)
            }
        }
        print("✅ Recalculation done")
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
    
    static func recalculateAllDays() async throws {
        let startDate = await fetchBackendDaysStartDate()

        var start = CFAbsoluteTimeGetCurrent()
        print("recalculateAllDays() started")
        let days = await fetchAllDaysFromDocuments(
            from: startDate,
            createIfNotExisting: false
        )
        print("     fetchAllDaysFromDocuments took: \(CFAbsoluteTimeGetCurrent()-start)s")
        start = CFAbsoluteTimeGetCurrent()
        try await recalculateAllDays(days)
        print("     recalculateAllDays took: \(CFAbsoluteTimeGetCurrent()-start)s")
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
