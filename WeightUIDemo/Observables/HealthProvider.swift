import SwiftUI

@Observable class HealthProvider {
    
    let isCurrent: Bool
    var healthDetails: HealthDetails

    init(
        isCurrent: Bool,
        healthDetails: HealthDetails
    ) {
        self.isCurrent = isCurrent
        self.healthDetails = healthDetails
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
/// [ ] Send a notification so that DailyValues set on this day get updated too

extension HealthProvider {
    
    func saveSex(_ sex: BiologicalSex) {
        healthDetails.sex = sex
        
        save()
    }
    
    func saveAge(_ age: HealthDetails.Age?) {
        healthDetails.age = age
        save()
    }
}

extension HealthProvider {
    //TODO: Replace this with actual backend manipulation in Prep
    func save() {
        saveHealthDetailsInDocuments(healthDetails)
    }
}
