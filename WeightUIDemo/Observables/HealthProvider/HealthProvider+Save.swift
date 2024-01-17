import Foundation
import HealthKit

//TODO: For each of these:
/// [ ] Recalculate any HealthDetails like calculated LBM, Resting Energy
/// [ ] This could affect plans so make sure this occurs
/// [ ] Send a notification so that DailyValues set on this day get updated too if dependent on the HealthDetail

extension HealthProvider {
    func save() {
        saveTask?.cancel()
        saveTask = Task {
            try await saveHealthDetailsInDocuments(healthDetails)
            try Task.checkCancellation()

            /// Recalculate all days
            try await Self.recalculateAllDays()
            
            /// Once complete, re-fetch the health details for this date and set it here in this provider
            let healthDetails = await fetchOrCreateHealthDetailsFromDocuments(healthDetails.date)
            self.healthDetails = healthDetails
        }
    }
}

extension HealthProvider {
    
    func saveMaintenance(_ maintenance: HealthDetails.Maintenance) {
        healthDetails.maintenance = maintenance
        save()
    }
    
    func saveDietaryEnergyPoint(_ point: DietaryEnergyPoint) {
        //TODO: Get any other HealthDetails (other than the one in this HealthProvider) that uses this point and get them to update within an instantiated HealthProvider as well
        Task {
            var day = await fetchOrCreateDayFromDocuments(point.date)
            day.dietaryEnergyPoint = point
            await saveDayInDocuments(day)
        }
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
    
    func saveFatPercentage(_ fatPercentage: HealthDetails.FatPercentage) {
        healthDetails.fatPercentage = fatPercentage
        save()
    }
    
    //TODO: Persist changes
    /// [ ] Replace Mock coding with actual persistence
    func updateLatestWeight(_ weight: HealthDetails.Weight) {
        guard let date = healthDetails.replacementsForMissing.datedWeight?.date else { return }
        healthDetails.replacementsForMissing.datedWeight?.weight = weight
        Task {
            try await saveWeight(weight, for: date)
        }
    }
    
    func updateLatestHeight(_ height: HealthDetails.Height) {
        guard let date = healthDetails.replacementsForMissing.datedHeight?.date else { return }
        healthDetails.replacementsForMissing.datedHeight?.height = height
        Task {
            try await saveHeight(height, for: date)
        }
    }
    
    func updateLatestPregnancyStatus(_ pregnancyStatus: PregnancyStatus) {
        guard let date = healthDetails.replacementsForMissing.datedPregnancyStatus?.date else { return }
        healthDetails.replacementsForMissing.datedPregnancyStatus?.pregnancyStatus = pregnancyStatus
        Task {
            try await savePregnancyStatus(pregnancyStatus, for: date)
        }
    }
    
    func updateLatestFatPercentage(_ fatPercentage: HealthDetails.FatPercentage) {
        guard let date = healthDetails.replacementsForMissing.datedFatPercentage?.date else { return }
        healthDetails.replacementsForMissing.datedFatPercentage?.fatPercentage = fatPercentage
        Task {
            try await saveFatPercentage(fatPercentage, for: date)
        }
    }
    
    func updateLatestLeanBodyMass(_ leanBodyMass: HealthDetails.LeanBodyMass) {
        guard let date = healthDetails.replacementsForMissing.datedLeanBodyMass?.date else { return }
        healthDetails.replacementsForMissing.datedLeanBodyMass?.leanBodyMass = leanBodyMass
        Task {
            try await saveLeanBodyMass(leanBodyMass, for: date)
        }
    }
    
    //MARK: - Save for other days
    
    func saveWeight(_ weight: HealthDetails.Weight, for date: Date) async throws {
        var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(date)
        healthDetails.weight = weight
        try await saveHealthDetailsInDocuments(healthDetails)
    }
    
    func saveHeight(_ height: HealthDetails.Height, for date: Date) async throws {
        var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(date)
        healthDetails.height = height
        try await saveHealthDetailsInDocuments(healthDetails)
    }
    
    func saveMaintenance(_ maintenance: HealthDetails.Maintenance, for date: Date) async throws {
        var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(date)
        healthDetails.maintenance = maintenance
        try await saveHealthDetailsInDocuments(healthDetails)
    }
    
    func savePregnancyStatus(_ pregnancyStatus: PregnancyStatus, for date: Date) async throws {
        var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(date)
        healthDetails.pregnancyStatus = pregnancyStatus
        try await saveHealthDetailsInDocuments(healthDetails)
    }
    
    func saveFatPercentage(_ fatPercentage: HealthDetails.FatPercentage, for date: Date) async throws {
        var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(date)
        healthDetails.fatPercentage = fatPercentage
        try await saveHealthDetailsInDocuments(healthDetails)
    }
    
    func saveLeanBodyMass(_ leanBodyMass: HealthDetails.LeanBodyMass, for date: Date) async throws {
        var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(date)
        healthDetails.leanBodyMass = leanBodyMass
        try await saveHealthDetailsInDocuments(healthDetails)
    }
}

extension HealthProvider {
    static func saveHealthKitSample(
        _ sample: HKQuantitySample,
        for quantityType: QuantityType
    ) async throws {
        let settings = await fetchSettingsFromDocuments()
        guard let dailyValueType = settings.dailyValueType(for: quantityType) else {
            return
        }
        var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(sample.date.startOfDay)
        switch quantityType {
        case .weight:
            healthDetails.weight.addHealthKitSample(sample, using: dailyValueType)
        case .leanBodyMass:
            healthDetails.leanBodyMass.addHealthKitSample(sample, using: dailyValueType)
        case .height:
            healthDetails.height.addHealthKitSample(sample, using: dailyValueType)
        case .fatPercentage:
            healthDetails.fatPercentage.addHealthKitSample(sample, using: dailyValueType)
        default:
            break
        }
        try await saveHealthDetailsInDocuments(healthDetails)
    }
}
