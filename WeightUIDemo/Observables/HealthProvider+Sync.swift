import SwiftUI
import HealthKit

extension HealthProvider {
    //TODO: Consider a rewrite
    /// [x] First add the source data into HealthKitMeasurement so that we can filter out what's form Apple or us
    /// [x] Rename to Sync with everything or something
    static func syncWithHealthKitAndRecalculateAllDays() async {
        
        var days = await fetchAllDaysFromDocuments()
        
        let start = CFAbsoluteTimeGetCurrent()
        
        /// Fetch all HealthKit weight samples from start of log (since we're not interested in any before that)
        let startDate = await fetchBackendLogStartDate()
        
        let settingsProvider = fetchSettingsFromDocuments()
        
        /// [x] First, fetch whatever isSynced is turned on for (weight, height, LBM)—fetch everything from the first Day's date onwards
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
        
        /// [ ] Go through each Day
        for i in days.indices {

            let day = days[i]
            print("Doing date: \(day.date.shortDateString)")

            if let weightSamples {
                var weight: HealthDetails.Weight {
                    get { days[i].healthDetails.weight }
                    set { days[i].healthDetails.weight = newValue }
                }
                
                let samples = weightSamples.filter { $0.date.startOfDay == day.date.startOfDay }
                weight.removeHealthKitQuantitySamples(notPresentIn: samples.notOurs)
                weight.addNewHealthKitQuantitySamples(from: samples.notOurs)
                toDelete.append(contentsOf: samples.ours.notPresent(in: weight.measurements))
                toExport.append(contentsOf: weight.measurements.nonHealthKitMeasurements.notPresent(in: samples.ours))
            }

            if let heightSamples {
                var height: HealthDetails.Height {
                    get { days[i].healthDetails.height }
                    set { days[i].healthDetails.height = newValue }
                }
                
                let samples = heightSamples.filter { $0.date.startOfDay == day.date.startOfDay }
                height.removeHealthKitQuantitySamples(notPresentIn: samples.notOurs)
                height.addNewHealthKitQuantitySamples(from: samples.notOurs)
                toDelete.append(contentsOf: samples.ours.notPresent(in: height.measurements))
                toExport.append(contentsOf: height.measurements.nonHealthKitMeasurements.notPresent(in: samples.ours))
            }
            
            if let leanBodyMassSamples {
                var leanBodyMass: HealthDetails.LeanBodyMass {
                    get { days[i].healthDetails.leanBodyMass }
                    set { days[i].healthDetails.leanBodyMass = newValue }
                }
                
                let samples = leanBodyMassSamples.filter { $0.date.startOfDay == day.date.startOfDay }
                leanBodyMass.removeHealthKitQuantitySamples(notPresentIn: samples.notOurs)
                leanBodyMass.addNewHealthKitQuantitySamples(from: samples.notOurs)
                toDelete.append(contentsOf: samples.ours.notPresent(in: leanBodyMass.measurements))
                toExport.append(contentsOf: leanBodyMass.measurements.nonHealthKitMeasurements.notPresent(in: samples.ours))
            }

            /// [ ] If the day has DietaryEnergyPointSource, RestingEnergySource or ActivieEnergySource as .healthKit, fetch them and set them

            /// [ ] Continue this for all Days
            /// [ ] Once we're doing, go ahead and delete all the measurements we put aside to be deleted
            /// [ ] Also export all the measurements we put aside

            saveDayInDocuments(days[i])
        }
        
        print("We have: \(toDelete.count) to delete")
        print("We have: \(toExport.count) to export")
        
        if !toDelete.isEmpty {
            let start = CFAbsoluteTimeGetCurrent()
            await HealthStore.deleteMeasurements(toDelete)
            print("Delete took: \(CFAbsoluteTimeGetCurrent()-start)s")
        }

        if !toExport.isEmpty {
            let start = CFAbsoluteTimeGetCurrent()
            await HealthStore.saveMeasurements(toExport)
            print("Export took: \(CFAbsoluteTimeGetCurrent()-start)s")
        }

        print("syncWithHealthKitAndRecalculateAllDays took: \(CFAbsoluteTimeGetCurrent()-start)s")
//        await recalculate(days)
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
        settingsProvider.save()
        recalculateAllDays()
    }
    
    func setHealthKitSyncing(for healthDetail: HealthDetail, to isOn: Bool) {
        settingsProvider.settings.setHealthKitSyncing(for: healthDetail, to: isOn)
        settingsProvider.save()
        if isOn {
//            resyncAndRecalculateAllDays()
        }
    }
    
    func recalculateAllDays() {
        Task {
            let days = await fetchAllDaysFromDocuments()
            await recalculate(days)
        }
    }
}
