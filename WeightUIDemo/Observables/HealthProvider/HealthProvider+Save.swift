import Foundation
import HealthKit

//TODO: For each of these:
/// [ ] Recalculate any HealthDetails like calculated LBM, Resting Energy
/// [ ] This could affect plans so make sure this occurs
/// [ ] Send a notification so that DailyValues set on this day get updated too if dependent on the HealthDetail

extension HealthProvider {
    func save(shouldResync: Bool = false) {
        let healthDetailsDidChange = healthDetails != unsavedHealthDetails
        
        /// Safeguard against any redundant calls to save to avoid cancelling the ongoing task and redundantly interacting with the backend
        guard healthDetailsDidChange || shouldResync else {
            print("🙅🏽‍♂️ Cancelling redundant save()")
            return
        }

        print("💾 Saving HealthProvider for: \(healthDetails.date.shortDateString)")

        saveTask?.cancel()
        saveTask = Task {
            /// Set this before we call `refetchHealthDetails()` which would override the `unsavedHealthDetails` making the changes undetectable
            let resync = shouldResync || healthDetails.containsChangesInSyncableMeasurements(from: unsavedHealthDetails)
            
            try await saveHealthDetailsInDocuments(healthDetails)
            try Task.checkCancellation()

            /// Do this first to ensure that recalculations happen instantly (since in most cases, the sync is simply to provide the Health App with new measurements)
            try await DayProvider.recalculateAllDays()

            /// Refetch HealthDetails as recalculations may have modified it further
            await refetchHealthDetails()

            try Task.checkCancellation()
            
            if resync  {
                print("✨ resync is true so Syncing")
                /// If any syncable measurements were changed, trigger a sync (and subsequent recalculate)
                try await Self.syncWithHealthKitAndRecalculateAllDays()

                /// Refetch HealthDetails as the sync and recalculate may have modified it further
                await refetchHealthDetails()
            } else {
                print("🥖 resync is false so not syncing")
            }
        }
    }
    
    func refetchHealthDetails() async {
        let healthDetails = await fetchOrCreateHealthDetailsFromDocuments(healthDetails.date)
        self.healthDetails = healthDetails

        /// Also save it as the `unsavedHealthDetails` so that we can check if a resync is needed with the next save
        self.unsavedHealthDetails = healthDetails
    }
}

extension HealthProvider {
    
    func saveMaintenance(_ maintenance: HealthDetails.Maintenance, shouldResync: Bool) {
        healthDetails.maintenance = maintenance
        save(shouldResync: shouldResync)
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
    
    //TODO: Replace Mock coding with actual persistence

    /// These trigger syncs if a modification was made
    func updateLatestWeight(_ weight: HealthDetails.Weight) {
        guard let date = healthDetails.replacementsForMissing.datedWeight?.date else { return }
        healthDetails.replacementsForMissing.datedWeight?.weight = weight
        
        Task {
            let shouldResync = try await saveWeight(weight, for: date)
            save(shouldResync: shouldResync)
        }
    }
    
    func updateLatestHeight(_ height: HealthDetails.Height) {
        guard let date = healthDetails.replacementsForMissing.datedHeight?.date else { return }
        healthDetails.replacementsForMissing.datedHeight?.height = height

        Task {
            let shouldResync = try await saveHeight(height, for: date)
            save(shouldResync: shouldResync)
        }
    }
    
    func updateLatestFatPercentage(_ fatPercentage: HealthDetails.FatPercentage) {
        guard let date = healthDetails.replacementsForMissing.datedFatPercentage?.date else { return }
        healthDetails.replacementsForMissing.datedFatPercentage?.fatPercentage = fatPercentage
        Task {
            let shouldResync = try await saveFatPercentage(fatPercentage, for: date)
            save(shouldResync: shouldResync)
        }
    }
    
    func updateLatestLeanBodyMass(_ leanBodyMass: HealthDetails.LeanBodyMass) {
        guard let date = healthDetails.replacementsForMissing.datedLeanBodyMass?.date else { return }
        healthDetails.replacementsForMissing.datedLeanBodyMass?.leanBodyMass = leanBodyMass
        Task {
            let shouldResync = try await saveLeanBodyMass(leanBodyMass, for: date)
            save(shouldResync: shouldResync)
        }
    }

    /// These do not trigger syncs if a modification was made
    func updateLatestMaintenance(_ maintenance: HealthDetails.Maintenance, shouldResync: Bool = false) {
        guard let date = healthDetails.replacementsForMissing.datedMaintenance?.date else { return }
        healthDetails.replacementsForMissing.datedMaintenance?.maintenance = maintenance
        Task {
            try await saveMaintenance(maintenance, for: date)
            save(shouldResync: shouldResync)
        }
    }

    
    func updateLatestPregnancyStatus(_ pregnancyStatus: PregnancyStatus) {
        guard let date = healthDetails.replacementsForMissing.datedPregnancyStatus?.date else { return }
        healthDetails.replacementsForMissing.datedPregnancyStatus?.pregnancyStatus = pregnancyStatus
        Task {
            try await savePregnancyStatus(pregnancyStatus, for: date)
            save()
        }
    }
    
    //MARK: - Save for other days
    
    /// The following would trigger a sync if any modifications were made, so their return values indicate whether a modification was made so that we don't redundantly cause a sync
    func saveWeight(_ weight: HealthDetails.Weight, for date: Date) async throws -> Bool {
        var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(date)
        guard healthDetails.weight != weight else {
            return false
        }
        healthDetails.weight = weight
        try await saveHealthDetailsInDocuments(healthDetails)
        return true
    }
    
    func saveHeight(_ height: HealthDetails.Height, for date: Date) async throws -> Bool {
        var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(date)
        guard healthDetails.height != height else {
            return false
        }
        healthDetails.height = height
        try await saveHealthDetailsInDocuments(healthDetails)
        return true
    }
    
    func saveFatPercentage(_ fatPercentage: HealthDetails.FatPercentage, for date: Date) async throws -> Bool {
        var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(date)
        guard healthDetails.fatPercentage != fatPercentage else {
            return false
        }
        healthDetails.fatPercentage = fatPercentage
        try await saveHealthDetailsInDocuments(healthDetails)
        return true
    }
    
    func saveLeanBodyMass(_ leanBodyMass: HealthDetails.LeanBodyMass, for date: Date) async throws -> Bool {
        var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(date)
        guard healthDetails.leanBodyMass != leanBodyMass else {
            return false
        }
        healthDetails.leanBodyMass = leanBodyMass
        try await saveHealthDetailsInDocuments(healthDetails)
        return true
    }
    
    /// We're not interested if the following result in modifications, as we wouldn't be triggering a sync even if they did (as we don't submit them to HealthKit)
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
            Task {
                try await HealthProvider.syncWithHealthKitAndRecalculateAllDays()
            }
        }
    }
}

extension HealthProvider {
    static func saveHealthKitSample(
        _ sample: HKQuantitySample,
        for quantityType: QuantityType
    ) async throws {
        let settings = await fetchSettingsFromDocuments()
        guard let dailyValueType = settings.dailyValueType(forQuantityType: quantityType) else {
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
