import SwiftUI

extension HealthProvider {
    //TODO: Consider a rewrite
    /// [x] First add the source data into HealthKitMeasurement so that we can filter out what's form Apple or us
    /// [x] Rename to Sync with everything or something
    func syncWithHealthKitAndRecalculate(_ days: [Day]) async {
        let start = CFAbsoluteTimeGetCurrent()
        
        /// Fetch all HealthKit weight samples from start of log (since we're not interested in any before that)
        let startDate = await fetchBackendLogStartDate()
        
        /// [x] First, fetch whatever isSynced is turned on for (weight, height, LBM)—fetch everything from the first Day's date onwards
        let weights = await HealthStore.weightMeasurements(from: startDate)
        let lbms = await HealthStore.leanBodyMassMeasurements(from: startDate)
        let heights = await HealthStore.heightMeasurements(from: startDate)
        
        /// Special case with height – if we have do not have any data within our app's timeframe—grab the latest height available and save it
        if heights.isEmpty == true, let latestHeight = await HealthStore.heightMeasurements().suffix(1).first
        {
            await saveHealthKitHeightMeasurement(latestHeight)
        }
        
        /// [ ] Go through each Day
        for day in days {
            print("Doing date: \(day.date.shortDateString)")
            /// [ ] For each Day, go through each fetched array and get all the values for that date
            let weights = weights.filter { $0.date.startOfDay == day.date.startOfDay }
            print("We have: \(weights.count) weights")

            let lbms = lbms.filter { $0.date.startOfDay == day.date.startOfDay }
            print("We have: \(lbms.count) lbms")

            let heights = heights.filter { $0.date.startOfDay == day.date.startOfDay }
            print("We have: \(heights.count) heights")

            /// [ ] Now sync with the day by removing any healthKit measurements we have that don't exist any more
            /// [ ] Also add any healthKit measurements that are present which we don't have
            /// [ ] Any HealthStore measurements that we provided that no longer are present on our side—put them aside to be deleted later
            /// [ ] Now any non-healthKit measurements we have that aren't present in HealthStore–put them aside to be exported later (we'll do it in a btach as opposed to a day at a time)
            /// [ ] Do this for all 3 types (weight, height, LBM)

            /// [ ] If the day has DietaryEnergyPointSource, RestingEnergySource or ActivieEnergySource as .healthKit, fetch them and set them

            /// [ ] Continue this for all Days
            /// [ ] Once we're doing, go ahead and delete all the measurements we put aside to be deleted
            /// [ ] Also export all the measurements we put aside
        }
        
        await recalculate(days)
    }
}

extension HealthProvider {
    func recalculate(_ days: [Day]) async {
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
        recalculateAllDays()
    }
    
    func setHealthKitSyncing(for healthDetail: HealthDetail, to isOn: Bool) {
        settingsProvider.settings.setHealthKitSyncing(for: healthDetail, to: isOn)
        if isOn {
            resyncAndRecalculateAllDays()
        }
    }
    
    func resyncAndRecalculateAllDays() {
        Task {
            let days = await fetchAllDaysFromDocuments()
            await syncWithHealthKitAndRecalculate(days)
        }
    }
    
    func recalculateAllDays() {
        Task {
            let days = await fetchAllDaysFromDocuments()
            await recalculate(days)
        }
    }
}
