import Foundation
import SwiftPrettyPrint

extension DayProvider {
    static func recalculateAllDays() async throws {
        let startDate = await fetchBackendDaysStartDate() ?? LogStartDate

        var start = CFAbsoluteTimeGetCurrent()
        print("recalculateAllDays() started")
        let days = await fetchAllDaysFromDocuments(
            from: startDate,
            createIfNotExisting: false
        )
        print("     fetchAllDaysFromDocuments took: \(CFAbsoluteTimeGetCurrent()-start)s")
        start = CFAbsoluteTimeGetCurrent()
        try await DayProvider.recalculateAllDays(days)
        print("     recalculateAllDays took: \(CFAbsoluteTimeGetCurrent()-start)s")
    }

    static func recalculateAllDays(
        _ days: [Date : Day],
        initialDays: [Date : Day]? = nil,
        syncStart: CFAbsoluteTime? = nil,
        cancellable: Bool = true
    ) async throws {
        
        print("🤖 recalculateAllDays started")

        let start = CFAbsoluteTimeGetCurrent()
        let initialDays = initialDays ?? days

        var latestHealthDetails: [HealthDetail: DatedHealthData] = [:]
        
        let settings = await fetchSettingsFromDocuments()
        let settingsProvider = SettingsProvider(settings: settings)

        if cancellable {
            try Task.checkCancellation()
        }
        
        for date in days.keys.sorted() {
            
            guard
                let value = days[date],
                let initialDay = initialDays[date]
            else {
                fatalError() /// Remove in production
            }
            
            var day = value

            /// Create a HealthProvider for it (which in turn fetches the latest health details)
            let healthProvider = HealthProvider(
                healthDetails: day.healthDetails,
                settingsProvider: settingsProvider
            )
            
            await healthProvider.recalculate(
                latestHealthDetails: latestHealthDetails,
                settings: settings,
                days: days
            )

            /// Set this to false after `recalculate` (where its used to avoid having it rewritten)
//            healthProvider.healthDetails.maintenance.isBroughtForward = false

            latestHealthDetails.extractLatestHealthDetails(from: day.healthDetails)
            
            day.healthDetails = healthProvider.healthDetails

            if cancellable {
                try Task.checkCancellation()
            }

            if initialDay.healthDetails != day.healthDetails {
                /// [ ] TBD: Reassign Daily Values after restructuring so that we store them in each `Day` as opposed to having a static list in Settings
                /// [ ] TBD: Recalculate any plans on this day too
            }

            if day != initialDay {
                await saveDayInDocuments(day)
            }
        }
        print("✅ recalculateAllDays done in: \(CFAbsoluteTimeGetCurrent()-start)s")
        if let syncStart {
            print("✅ syncWithHealthKitAndRecalculateAllDays done in: \(CFAbsoluteTimeGetCurrent()-syncStart)s")
        }
    }
}
