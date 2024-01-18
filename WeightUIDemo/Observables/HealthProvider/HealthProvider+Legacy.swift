//MARK: - Legacy Sync

//extension HealthProvider {
//
//    static func _syncWithHealthKitAndRecalculateAllDays() async throws {
//
//        let start = CFAbsoluteTimeGetCurrent()
//
//        let settings = await fetchSettingsFromDocuments()
//
//        /// Fetch all HealthKit weight samples from start of log (since we're not interested in any before that)
//        let logStartDate = await DayProvider.fetchBackendLogStartDate()
//        var daysStartDate = logStartDate
//
//        /// First, fetch whatever isSynced is turned on for (weight, height, LBM)—fetch everything from the first Day's date onwards
//        var weightSamples: [HKQuantitySample]? = if settings.isHealthKitSyncing(.weight) {
//            await HealthStore.samples(for: .weight, from: logStartDate)
//        } else {
//            nil
//        }
//        var leanBodyMassSamples: [HKQuantitySample]? = if settings.isHealthKitSyncing(.leanBodyMass) {
//            await HealthStore.samples(for: .leanBodyMass, from: logStartDate)
//        } else {
//            nil
//        }
//        var fatPercentageSamples: [HKQuantitySample]? = if settings.isHealthKitSyncing(.fatPercentage) {
//            await HealthStore.samples(for: .fatPercentage, from: logStartDate)
//        } else {
//            nil
//        }
//        var heightSamples: [HKQuantitySample]? = if settings.isHealthKitSyncing(.height) {
//            await HealthStore.samples(for: .height, from: logStartDate)
//        } else {
//            nil
//        }
//
//        /// If we have do not have any data within our app's timeframe—grab the latest available and create a Day and save it
//
//        if heightSamples.isEmptyOrNil,
//            let sample = await HealthStore.mostRecentSample(for: .height)
//        {
//            if sample.startDate < daysStartDate { daysStartDate = sample.startDate }
//            /// This is crucial, otherwise it not being included in the array has the value
//            heightSamples = [sample]
//            try await saveHealthKitSample(sample, for: .height)
//        }
//        if weightSamples.isEmptyOrNil,
//            let sample = await HealthStore.mostRecentSample(for: .weight)
//        {
//            if sample.startDate < daysStartDate { daysStartDate = sample.startDate }
//            weightSamples = [sample]
//            try await saveHealthKitSample(sample, for: .weight)
//        }
//        if leanBodyMassSamples.isEmptyOrNil,
//            let sample = await HealthStore.mostRecentSample(for: .leanBodyMass)
//        {
//            if sample.startDate < daysStartDate { daysStartDate = sample.startDate }
//            leanBodyMassSamples = [sample]
//            try await saveHealthKitSample(sample, for: .leanBodyMass)
//        }
//        if fatPercentageSamples.isEmptyOrNil,
//           let sample = await HealthStore.mostRecentSample(for: .fatPercentage)
//        {
//            if sample.startDate < daysStartDate { daysStartDate = sample.startDate }
//            fatPercentageSamples = [sample]
//            try await saveHealthKitSample(sample, for: .fatPercentage)
//        }
//
//        let startD = CFAbsoluteTimeGetCurrent()
//        let dietaryStartDate = logStartDate.moveDayBy(-(HealthInterval(MaxAdaptiveWeeks, .week).numberOfDays))
//        let dietaryEnergyStats = await HealthStore.dailyStatistics(
//            for: .dietaryEnergyConsumed,
//            from: dietaryStartDate,
//            to: Date.now
//        )
//        print("Getting all DietaryEnergy took: \(CFAbsoluteTimeGetCurrent()-startD)s")
//        print("Fetching or Creating all days for dietary starting from: \(dietaryStartDate.shortDateString)")
//        let startDD = CFAbsoluteTimeGetCurrent()
//        var dietaryDays = await fetchAllDaysFromDocuments(
//            from: dietaryStartDate,
//            to: logStartDate.moveDayBy(-1),
//            createIfNotExisting: true
//        )
//        print("Took: \(CFAbsoluteTimeGetCurrent()-startDD)s")
//        print("Fetching dietary energy point from HealthKit for all those days")
//        let startDD2 = CFAbsoluteTimeGetCurrent()
//        for (index, dietaryDay) in dietaryDays.enumerated() {
//            /// If the point doesn't exist, create it
//            if dietaryDay.dietaryEnergyPoint == nil {
//                if let kcal = await HealthStore.dietaryEnergyTotalInKcal(
//                    for: dietaryDay.date,
//                    using: dietaryEnergyStats
//                ) {
//                    dietaryDays[index].dietaryEnergyPoint = .init(
//                        date: dietaryDay.date,
//                        kcal: kcal,
//                        source: .healthKit
//                    )
//                } else {
//                    dietaryDays[index].dietaryEnergyPoint = .init(
//                        date: dietaryDay.date,
//                        source: .notCounted
//                    )
//                }
//            } else {
//                await dietaryDays[index].dietaryEnergyPoint?.fetchFromHealthKitIfNeeded(
//                    day: dietaryDay,
//                    using: dietaryEnergyStats
//                )
//            }
//
//            if dietaryDays[index] != dietaryDay {
//                await saveDayInDocuments(dietaryDays[index])
//            }
//        }
//        print("Took: \(CFAbsoluteTimeGetCurrent()-startDD2)s")
//
//        var days = await fetchAllDaysFromDocuments(
//            from: daysStartDate,
//            createIfNotExisting: false
//        )
//        let initialDays = days
//
//        var toDelete: [HKQuantitySample] = []
//        var toExport: [any Measurable] = []
//
//        let startR = CFAbsoluteTimeGetCurrent()
//        let restingEnergyStats = await HealthStore.dailyStatistics(
//            for: .basalEnergyBurned,
//            from: logStartDate,
//            to: Date.now
//        )
//        print("Getting all RestingEnergy took: \(CFAbsoluteTimeGetCurrent()-startR)s")
//
//        let startA = CFAbsoluteTimeGetCurrent()
//        let activeEnergyStats = await HealthStore.dailyStatistics(
//            for: .activeEnergyBurned,
//            from: logStartDate,
//            to: Date.now
//        )
//        print("Getting all ActiveEnergy took: \(CFAbsoluteTimeGetCurrent()-startA)s")
//
//        /// Go through each Day
//        for i in days.indices {
//
//            let day = days[i]
//            let date = day.date
//
////            print("Syncing HealthKit values for: \(day.date.shortDateString)")
//
//            if let weightSamples {
//                days[i].healthDetails.weight.processHealthKitSamples(
//                    weightSamples,
//                    for: date,
//                    toDelete: &toDelete,
//                    toExport: &toExport,
//                    settings: settings
//                )
//            }
//
//            if let heightSamples {
//                days[i].healthDetails.height.processHealthKitSamples(
//                    heightSamples,
//                    for: date,
//                    toDelete: &toDelete,
//                    toExport: &toExport,
//                    settings: settings
//                )
//            }
//
//            if let leanBodyMassSamples {
//                days[i].healthDetails.leanBodyMass.processHealthKitSamples(
//                    leanBodyMassSamples,
//                    for: date,
//                    toDelete: &toDelete,
//                    toExport: &toExport,
//                    settings: settings
//                )
//            }
//
//            if let fatPercentageSamples {
//                days[i].healthDetails.fatPercentage.processHealthKitSamples(
//                    fatPercentageSamples,
//                    for: day.date,
//                    toDelete: &toDelete,
//                    toExport: &toExport,
//                    settings: settings
//                )
//            }
//
//            /// If the day has RestingEnergySource or ActivieEnergySource as .healthKit, fetch them and set them
//            await days[i].healthDetails.maintenance.estimate.restingEnergy
//                .mock_fetchFromHealthKitIfNeeded(for: date, using: restingEnergyStats)
//
//            await days[i].healthDetails.maintenance.estimate.activeEnergy
//                .mock_fetchFromHealthKitIfNeeded(for: date, using: activeEnergyStats)
//        }
//
//        /// Once we're done, go ahead and delete all the measurements we put aside to be deleted
//        if !toDelete.isEmpty {
//            await HealthStore.deleteMeasurements(toDelete)
//        }
//
//        /// Also export all the measurements we put aside
//        if !toExport.isEmpty {
//            await HealthStore.saveMeasurements(toExport)
//        }
//
//        try await DayProvider.recalculateAllDays(
//            days,
//            initialDays: initialDays,
//            start: start,
//            cancellable: false /// Disallow the recalculation to be cancellable as the sync takes some time and any new recalculation
//        )
//    }
//}
