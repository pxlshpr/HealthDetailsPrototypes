import SwiftUI
import HealthKit

@Observable class HealthProvider {
    
    var settingsProvider: SettingsProvider
    
    let isCurrent: Bool
    
    var unsavedHealthDetails: HealthDetails
    var healthDetails: HealthDetails
    
    var saveTask: Task<Void, Error>? = nil
    
    init(
        healthDetails: HealthDetails,
        settingsProvider: SettingsProvider
    ) {
        self.settingsProvider = settingsProvider
        self.isCurrent = healthDetails.date.isToday
        self.unsavedHealthDetails = healthDetails
        self.healthDetails = healthDetails
    }
}

#Preview("Demo") {
    DemoView()
}
