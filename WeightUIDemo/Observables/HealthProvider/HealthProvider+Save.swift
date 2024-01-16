import Foundation
import HealthKit

//TODO: For each of these:
/// [ ] Recalculate any HealthDetails like calculated LBM, Resting Energy
/// [ ] This could affect plans so make sure this occurs
/// [ ] Send a notification so that DailyValues set on this day get updated too if dependent on the HealthDetail

extension HealthProvider {

    func saveMaintenance(_ maintenance: HealthDetails.Maintenance) {
        healthDetails.maintenance = maintenance
        save()
    }
    
    func saveDietaryEnergyPoint(_ point: DietaryEnergyPoint) {
        var day = fetchOrCreateDayFromDocuments(point.date)
        day.dietaryEnergyPoint = point
        //TODO: Get any other HealthDetails (other than the one in this HealthProvider) that uses this point and get them to update within an instantiated HealthProvider as well
        saveDayInDocuments(day)
    }

    func saveRestingEnergy(_ restingEnergy: HealthDetails.Maintenance.Estimate.RestingEnergy) {
        healthDetails.maintenance.estimate.restingEnergy = restingEnergy
        save()
    }

    func saveEstimate(_ estimate: HealthDetails.Maintenance.Estimate) {
        healthDetails.maintenance.estimate = estimate
        save()
    }

    func saveActiveEnergy(_ activeEnergy: HealthDetails.Maintenance.Estimate.ActiveEnergy) {
        healthDetails.maintenance.estimate.activeEnergy = activeEnergy
        save()
    }

    func savePregnancyStatus(_ pregnancyStatus: PregnancyStatus) {
        healthDetails.pregnancyStatus = pregnancyStatus
        save()
    }
    
    func saveBiologicalSex(_ sex: BiologicalSex) {
        healthDetails.biologicalSex = sex
        save()
    }
    
    func saveDateOfBirth(_ date: Date?) {
        healthDetails.dateOfBirth = date
        save()
    }

    func saveSmokingStatus(_ smokingStatus: SmokingStatus) {
        healthDetails.smokingStatus = smokingStatus
        save()
    }
    
    //TODO: Sync stuff
    /// [ ] Handle sync being turned on and off for these here
    func saveHeight(_ height: HealthDetails.Height) {
        healthDetails.height = height
        save()
    }
    
    func saveWeight(_ weight: HealthDetails.Weight) {
        healthDetails.weight = weight
        save()
    }
    
    func saveLeanBodyMass(_ leanBodyMass: HealthDetails.LeanBodyMass) {
        healthDetails.leanBodyMass = leanBodyMass
        save()
    }
    
    //TODO: Persist changes
    /// [ ] Replace Mock coding with actual persistence
    func updateLatestWeight(_ weight: HealthDetails.Weight) {
        guard let date = latest.datedWeight?.date else { return }
        latest.weight = weight
        Task {
            await saveWeight(weight, for: date)
        }
    }
    
    func updateLatestHeight(_ height: HealthDetails.Height) {
        guard let date = latest.datedHeight?.date else { return }
        latest.height = height
        Task {
            await saveHeight(height, for: date)
        }
    }
    
    func updateLatestPregnancyStatus(_ pregnancyStatus: PregnancyStatus) {
        guard let date = latest.datedPregnancyStatus?.date else { return }
        latest.pregnancyStatus = pregnancyStatus
        Task {
            await savePregnancyStatus(pregnancyStatus, for: date)
        }
    }

    func updateLatestLeanBodyMass(_ leanBodyMass: HealthDetails.LeanBodyMass) {
        guard let date = latest.datedLeanBodyMass?.date else { return }
        latest.leanBodyMass = leanBodyMass
        Task {
            await saveLeanBodyMass(leanBodyMass, for: date)
        }
    }
    
    //MARK: - Save for other days

    func saveWeight(_ weight: HealthDetails.Weight, for date: Date) async {
        var healthDetails = fetchOrCreateHealthDetailsFromDocuments(date)
        healthDetails.weight = weight
        saveHealthDetailsInDocuments(healthDetails)
    }

    func saveHeight(_ height: HealthDetails.Height, for date: Date) async {
        var healthDetails = fetchOrCreateHealthDetailsFromDocuments(date)
        healthDetails.height = height
        saveHealthDetailsInDocuments(healthDetails)
    }

    func saveMaintenance(_ maintenance: HealthDetails.Maintenance, for date: Date) async {
        var healthDetails = fetchOrCreateHealthDetailsFromDocuments(date)
        healthDetails.maintenance = maintenance
        saveHealthDetailsInDocuments(healthDetails)
    }

    func savePregnancyStatus(_ pregnancyStatus: PregnancyStatus, for date: Date) async {
        var healthDetails = fetchOrCreateHealthDetailsFromDocuments(date)
        healthDetails.pregnancyStatus = pregnancyStatus
        saveHealthDetailsInDocuments(healthDetails)
    }
    
    func saveLeanBodyMass(_ leanBodyMass: HealthDetails.LeanBodyMass, for date: Date) async {
        var healthDetails = fetchOrCreateHealthDetailsFromDocuments(date)
        healthDetails.leanBodyMass = leanBodyMass
        saveHealthDetailsInDocuments(healthDetails)
    }
    
    static func saveHealthKitHeightMeasurement(_ measurement: HKQuantitySample) async {
        var healthDetails = fetchOrCreateHealthDetailsFromDocuments(measurement.date)
        healthDetails.height.addHealthKitSample(measurement)
        saveHealthDetailsInDocuments(healthDetails)
    }
}
