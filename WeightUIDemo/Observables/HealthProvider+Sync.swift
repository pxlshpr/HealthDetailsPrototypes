import SwiftUI

extension HealthProvider {
    //TODO: Consider a rewrite
    /// [x] First add the source data into HealthKitMeasurement so that we can filter out what's form Apple or us
    /// [x] Rename to Sync with everything or something
    func syncMeasurementsWithHealthKit() async {
        let start = CFAbsoluteTimeGetCurrent()
        
        /// Fetch all HealthKit weight samples from start of log (since we're not interested in any before that)
        let startDate = await fetchBackendLogStartDate()
        
        /// [x] First, fetch whatever isSynced is turned on for (weight, height, LBM)—fetch everything from the first Day's date onwards
        let weights: [HealthKitMeasurement]? = if settingsProvider.weightIsHealthKitSynced {
            await HealthStore.weightMeasurements(from: startDate)
        } else { nil }
        
        let leanBodyMasses: [HealthKitMeasurement]? = if settingsProvider.leanBodyMassIsHealthKitSynced {
            await HealthStore.leanBodyMassMeasurements(from: startDate)
        } else { nil }
        
        let heights: [HealthKitMeasurement]? = if settingsProvider.heightIsHealthKitSynced {
            await HealthStore.heightMeasurements(from: startDate)
        } else { nil }
        
        /// Special case with height – if we have do not have any data within our app's timeframe—grab the latest height available and save it
        if (heights == nil || heights?.isEmpty == true),
           let latestHeight = await HealthStore.heightMeasurements().suffix(1).first
        {
            await saveHealthKitHeightMeasurement(latestHeight)
        }
        
        /// [ ] Now fetch all the Day's we have in our backend, optimizing by not fetching the meals etc when do so
        /// [ ] Go through each Day
        /// [ ] For each Day, go through each fetched array and get all the values for that date
        /// [ ] Now sync with the day by removing any healthKit measurements we have that don't exist any more
        /// [ ] Also add any healthKit measurements that are present which we don't have
        /// [ ] Any HealthStore measurements that we provided that no longer are present on our side—put them aside to be deleted later
        /// [ ] Now any non-healthKit measurements we have that aren't present in HealthStore–put them aside to be exported later (we'll do it in a btach as opposed to a day at a time)
        /// [ ] Do this for all 3 types (weight, height, LBM)
        /// [ ] Now if any changes were made, recalculate the HealthDetails in its entirety by
        /// [ ] Recalculating any dependent equations we have (LBM, Resting Energy)
        /// [ ] Recalculating the AdaptiveMaintenance WeightChange if needed, and hence adaptive, and then maintenance (do a sanity check that this would account for all weight changes for moving average by the time we reach a date, given that we're going in order of the days)
        /// [ ] Now recalculate the plans for the Day as HealthDetails have changed
        /// [ ] Continue this for all Days
        /// [ ] Once we're doing, go ahead and delete all the measurements we put aside to be deleted
        /// [ ] Also add all the measurements we put aside to be added
        
        print("Got measurements in: \(CFAbsoluteTimeGetCurrent()-start)s")
        print("\(weights?.count ?? 0) weights")
        print("\(heights?.count ?? 0) heights")
        print("\(leanBodyMasses?.count ?? 0) leanBodyMasses")
    }
}

extension HealthProvider {
    func setHealthKitSyncing(for healthDetail: HealthDetail, to isOn: Bool) {
        settingsProvider.settings.setHealthKitSyncing(for: healthDetail, to: isOn)
        if isOn {
            Task {
                await syncMeasurementsWithHealthKit()
                await recalculate()
            }
        }
    }
}
