import SwiftUI

@Observable class HealthProvider {
    
    let isCurrent: Bool
    var healthDetails: HealthDetails
    
    var latest: LatestHealthDetails
    
    
    struct LatestHealthDetails {
        var weight: Weight?
        var height: Height?

        struct Weight {
            let date: Date
            var weight: HealthDetails.Weight
        }
        
        struct Height {
            let date: Date
            var height: HealthDetails.Height
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

//TODO: For each of these:
/// [ ] Recalculate any HealthDetails like calculated LBM, Resting Energy
/// [ ] This could affect plans so make sure this occurs
/// [ ] Send a notification so that DailyValues set on this day get updated too if dependent on the HealthDetail

extension HealthProvider {
    
    func savePregnancyStatus(_ pregnancyStatus: PregnancyStatus) {
        healthDetails.pregnancyStatus = pregnancyStatus
        save()
    }
    
    func saveSex(_ sex: BiologicalSex) {
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
}

//TODO: Replace this with actual backend manipulation in Prep
extension HealthProvider {
    func save() {
        saveHealthDetailsInDocuments(healthDetails)
    }
}
