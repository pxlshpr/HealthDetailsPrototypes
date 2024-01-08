import SwiftUI

@Observable class HealthProvider {
    
    let isCurrent: Bool
    var healthDetails: HealthDetails
    
    var latest: LatestHealthDetails
    
    var currentOrLatestWeightInKg: Double? {
        healthDetails.weight.weightInKg ?? latest.weight?.weight.weightInKg
    }

    var currentOrLatestMaintenanceInKcal: Double? {
        healthDetails.maintenance.kcal ?? latest.maintenance?.maintenance.kcal
    }

    var currentOrLatestLeanBodyMassInKg: Double? {
        healthDetails.leanBodyMass.leanBodyMassInKg ?? latest.leanBodyMass?.leanBodyMass.leanBodyMassInKg
    }

    var currentOrLatestHeightInCm: Double? {
        healthDetails.height.heightInCm ?? latest.height?.height.heightInCm
    }
    
    var biologicalSex: BiologicalSex {
        healthDetails.biologicalSex
    }
    
    var ageInYears: Int? {
        healthDetails.ageInYears
    }

    struct LatestHealthDetails {
        var weight: Weight?
        var height: Height?
        var leanBodyMass: LeanBodyMass?
        var maintenance: Maintenance?
        var pregnancyStatus: PregnancyStatus?

        struct LeanBodyMass {
            let date: Date
            var leanBodyMass: HealthDetails.LeanBodyMass
        }
        
        struct Weight {
            let date: Date
            var weight: HealthDetails.Weight
        }
        
        struct Height {
            let date: Date
            var height: HealthDetails.Height
        }

        struct Maintenance {
            let date: Date
            var maintenance: HealthDetails.Maintenance
        }

        struct PregnancyStatus {
            let date: Date
            var pregnancyStatus: WeightUIDemo.PregnancyStatus
        }
    }

    init(
        isCurrent: Bool,
        healthDetails: HealthDetails,
        latest: LatestHealthDetails = LatestHealthDetails()
    ) {
        self.isCurrent = isCurrent
        self.healthDetails = healthDetails
        self.latest = latest
    }
    
    /// Returns the date of the `HealthDetails` struct if not current, otherwise returns nil
    var pastDate: Date? {
        guard !isCurrent else { return nil }
        return healthDetails.date
    }
}

extension HealthDetails {
    var missingNonTemporalHealthDetails: [HealthDetail] {
        HealthDetail.allNonTemporalHealthDetails.filter { !hasSet($0) }
    }

    func hasSet(_ healthDetail: HealthDetail) -> Bool {
        switch healthDetail {
        case .maintenance:
            maintenance.kcal != nil
        case .age:
            ageInYears != nil
        case .sex:
            biologicalSex != .notSet
        case .weight:
            weight.weightInKg != nil
        case .leanBodyMass:
            leanBodyMass.leanBodyMassInKg != nil
        case .height:
            height.heightInCm != nil
        case .preganancyStatus:
            pregnancyStatus != .notSet
        case .smokingStatus:
            smokingStatus != .notSet
        }
    }

    func secondaryValueString(
        for healthDetail: HealthDetail,
        _ settingsProvider: SettingsProvider
    ) -> String? {
        switch healthDetail {
        case .leanBodyMass:
            leanBodyMass.secondaryValueString()
        default:
            nil
        }
    }
    func valueString(
        for healthDetail: HealthDetail,
        _ settingsProvider: SettingsProvider
    ) -> String {
        switch healthDetail {
        case .age:
            if let ageInYears {
                "\(ageInYears)"
            } else {
                "Not Set"
            }
        case .sex:
            biologicalSex.name
        case .weight:
            weight.valueString(in: settingsProvider.bodyMassUnit)
        case .leanBodyMass:
            leanBodyMass.valueString(in: settingsProvider.bodyMassUnit)
        case .height:
            height.valueString(in: settingsProvider.heightUnit)
        case .preganancyStatus:
            pregnancyStatus.name
        case .smokingStatus:
            smokingStatus.name
        case .maintenance:
            maintenance.valueString(in: settingsProvider.energyUnit)
        }
    }
}

//TODO: For each of these:
/// [ ] Recalculate any HealthDetails like calculated LBM, Resting Energy
/// [ ] This could affect plans so make sure this occurs
/// [ ] Send a notification so that DailyValues set on this day get updated too if dependent on the HealthDetail

extension HealthProvider {

    func saveMaintenance(_ maintenance: HealthDetails.Maintenance) {
        healthDetails.maintenance = maintenance
        save()
    }

    func saveRestingEnergy(_ restingEnergy: HealthDetails.Maintenance.Estimate.RestingEnergy) {
        healthDetails.maintenance.estimate.restingEnergy = restingEnergy
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
        guard let latestWeight = latest.weight else { return }
        latest.weight?.weight = weight
        
        var healthDetails = fetchHealthDetailsFromDocuments(latestWeight.date)
        healthDetails.weight = weight
        saveHealthDetailsInDocuments(healthDetails)
    }
    
    func updateLatestHeight(_ height: HealthDetails.Height) {
        guard let latestHeight = latest.height else { return }
        latest.height?.height = height
        
        var healthDetails = fetchHealthDetailsFromDocuments(latestHeight.date)
        healthDetails.height = height
        saveHealthDetailsInDocuments(healthDetails)
    }

    func updateLatestMaintenance(_ maintenance: HealthDetails.Maintenance) {
        guard let latestMaintenance = latest.maintenance else { return }
        latest.maintenance?.maintenance = maintenance
        
        var healthDetails = fetchHealthDetailsFromDocuments(latestMaintenance.date)
        healthDetails.maintenance = maintenance
        saveHealthDetailsInDocuments(healthDetails)
    }

    func updateLatestPregnancyStatus(_ pregnancyStatus: PregnancyStatus) {
        guard let latestPregnancyStatus = latest.pregnancyStatus else { return }
        latest.pregnancyStatus?.pregnancyStatus = pregnancyStatus
        
        var healthDetails = fetchHealthDetailsFromDocuments(latestPregnancyStatus.date)
        healthDetails.pregnancyStatus = pregnancyStatus
        saveHealthDetailsInDocuments(healthDetails)
    }

    func updateLatestLeanBodyMass(_ leanBodyMass: HealthDetails.LeanBodyMass) {
        guard let latestLeanBodyMass = latest.leanBodyMass else { return }
        latest.leanBodyMass?.leanBodyMass = leanBodyMass
        
        var healthDetails = fetchHealthDetailsFromDocuments(latestLeanBodyMass.date)
        healthDetails.leanBodyMass = leanBodyMass
        saveHealthDetailsInDocuments(healthDetails)
    }

}

//TODO: Replace this with actual backend manipulation in Prep
extension HealthProvider {
    func save() {
        saveHealthDetailsInDocuments(healthDetails)
    }
}
