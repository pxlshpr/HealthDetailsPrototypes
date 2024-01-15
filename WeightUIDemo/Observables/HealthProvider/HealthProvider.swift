import SwiftUI
import HealthKit

@Observable class HealthProvider {
    
    var settingsProvider: SettingsProvider
    
    let isCurrent: Bool
    var healthDetails: HealthDetails
    
//    var latest: LatestHealthDetails = LatestHealthDetails()
    var latest: [HealthDetail : DatedHealthData] = [:]

    init(
        healthDetails: HealthDetails,
        settingsProvider: SettingsProvider
    ) {
        self.settingsProvider = settingsProvider
        self.isCurrent = healthDetails.date.isToday
        self.healthDetails = healthDetails
    }
}

extension HealthProvider {
//    func setup() async {
//        let start = CFAbsoluteTimeGetCurrent()
//        await self.loadLatestHealthDetails()
//        await self.bringForwardNonTemporalHealthDetails()
//        print("\(healthDetails.date.shortDateString) setup() took: \(CFAbsoluteTimeGetCurrent()-start)s")
//    }
}

#Preview("Demo") {
    DemoView()
}
