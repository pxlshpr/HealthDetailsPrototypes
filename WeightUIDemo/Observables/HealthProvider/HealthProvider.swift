import SwiftUI
import HealthKit

@Observable class HealthProvider {
    
    var settingsProvider: SettingsProvider
    
    let isCurrent: Bool
    var healthDetails: HealthDetails
    
    init(
        healthDetails: HealthDetails,
        settingsProvider: SettingsProvider
    ) {
        self.settingsProvider = settingsProvider
        self.isCurrent = healthDetails.date.isToday
        self.healthDetails = healthDetails
    }
}

#Preview("Demo") {
    DemoView()
}
