import Foundation

extension DayProvider {
    static func recalculateAllDays() async throws {
        let startDate = await fetchBackendDaysStartDate()

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
        _ days: [Day],
        initialDays: [Day]? = nil,
        start: CFAbsoluteTime? = nil,
        cancellable: Bool = true
    ) async throws {
        
        print("🤖 recalculateAllDays started")

        let start = start ?? CFAbsoluteTimeGetCurrent()
        let initialDays = initialDays ?? days

        var latestHealthDetails: [HealthDetail: DatedHealthData] = [:]
        
        let settings = await fetchSettingsFromDocuments()
        let settingsProvider = SettingsProvider(settings: settings)

        if cancellable {
            try Task.checkCancellation()
        }
        
        for (index, day) in days.enumerated() {
            
            let initialDay = initialDays[index]
            var day = day
            
            /// [ ] Create a HealthProvider for it (which in turn fetches the latest health details)
            let healthProvider = HealthProvider(
                healthDetails: day.healthDetails,
                settingsProvider: settingsProvider
            )
            
            await healthProvider.recalculate(
                latestHealthDetails: latestHealthDetails,
                settings: settings
            )

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
        print("✅ recalculateAllDays done")
    }
}
