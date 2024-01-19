import SwiftUI
import SwiftPrettyPrint

public var isPreview: Bool {
    return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

struct MockHealthDetailsForm: View {
    
    @Bindable var settingsProvider: SettingsProvider

    @State var healthProvider: HealthProvider? = nil
    @Binding var isPresented: Bool
    
    let date: Date
    
    init(
        date: Date,
        settingsProvider: SettingsProvider,
        isPresented: Binding<Bool> = .constant(true)
    ) {
        self.date = date
        self.settingsProvider = settingsProvider
        _isPresented = isPresented
        
//        let healthDetails = fetchOrCreateHealthDetailsFromDocuments(date)
//        let healthProvider = HealthProvider(
//            healthDetails: healthDetails,
//            settingsProvider: settingsProvider
//        )
//        _healthProvider = State(initialValue: healthProvider)
    }

    var body: some View {
        if let healthProvider {
            HealthDetailsForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        } else {
            Color.clear
                .onAppear {
                    Task {
                        let healthDetails = await fetchOrCreateHealthDetailsFromDocuments(date)
                        let healthProvider = HealthProvider(
                            healthDetails: healthDetails,
                            settingsProvider: settingsProvider
                        )
                        await MainActor.run {
                            self.healthProvider = healthProvider
                        }
                    }
                }
        }
    }
}

//MARK: Reusable

func deleteAllFilesInDocuments() {
    do {
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: getDocumentsDirectory(),
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )
        for fileURL in fileURLs {
            try FileManager.default.removeItem(at: fileURL)
        }
    } catch  {
        print(error)
    }
}

func getDocumentsDirectory() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}

func fetchOrCreateDayFromDocuments(_ date: Date) async -> Day {
    let filename = "\(date.dateString).json"
    let url = getDocumentsDirectory().appendingPathComponent(filename)
    do {
        let data = try Data(contentsOf: url)
        let day = try JSONDecoder().decode(Day.self, from: data)
        return day
    } catch {
        let day = Day(date: date)
        await saveDayInDocuments(day)
        return day
    }
}

func fetchAllPreLogDaysFromDocuments() async -> [Date : Day] {
    guard let daysStartDate = await DayProvider.fetchBackendDaysStartDate() else {
        return [:]
    }
    let logStartDate = await DayProvider.fetchBackendLogStartDate()
    return await fetchAllDaysFromDocuments(
        from: daysStartDate,
        to: logStartDate,
        createIfNotExisting: false
    )
}

func fetchAllDaysFromDocuments(
    from startDate: Date,
    to endDate: Date = Date.now,
    createIfNotExisting: Bool
) async -> [Date : Day] {
    //TODO: In production:
    /// [ ] Optimizing by not fetching the meals etc, only fetching fields we need
    var days: [Date : Day] = [:]
    for i in (0...endDate.numberOfDaysFrom(startDate)).reversed() {
        let date = endDate.moveDayBy(-i)
        let day = if createIfNotExisting {
            await fetchOrCreateDayFromDocuments(date)
        } else {
            await fetchDayFromDocuments(date)
        }
        if let day {
            days[date.startOfDay] = day
        }
    }
    return days
}

func _fetchAllDaysFromDocuments(
    from startDate: Date,
    to endDate: Date = Date.now,
    createIfNotExisting: Bool
) async -> [Day] {
    //TODO: In production:
    /// [ ] Optimizing by not fetching the meals etc, only fetching fields we need
    var days: [Day] = []
    for i in (0...endDate.numberOfDaysFrom(startDate)).reversed() {
        let date = endDate.moveDayBy(-i)
        let day = if createIfNotExisting {
            await fetchOrCreateDayFromDocuments(date)
        } else {
            await fetchDayFromDocuments(date)
        }
        if let day {
            days.append(day)
        }
    }
    return days
}

func fetchDayFromDocuments(_ date: Date) async -> Day? {
    let filename = "\(date.dateString).json"
    let url = getDocumentsDirectory().appendingPathComponent(filename)
    do {
        let data = try Data(contentsOf: url)
        let day = try JSONDecoder().decode(Day.self, from: data)
        return day
    } catch {
        return nil
    }
}

func saveDayInDocuments(_ day: Day) async {
    Pretty.print("⭐️ Saving day:")
    Pretty.prettyPrint(day)
    Pretty.print(" ")
    do {
        let filename = "\(day.date.dateString).json"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        let json = try JSONEncoder().encode(day)
        try json.write(to: url)
    } catch {
        fatalError()
    }
}

func fetchOrCreateHealthDetailsFromDocuments(_ date: Date) async -> HealthDetails {
    await fetchOrCreateDayFromDocuments(date).healthDetails
}

func fetchHealthDetailsFromDocuments(_ date: Date) async -> HealthDetails? {
    await fetchDayFromDocuments(date)?.healthDetails
}

func saveHealthDetailsInDocuments(_ healthDetails: HealthDetails) async throws {
    var day = await fetchOrCreateDayFromDocuments(healthDetails.date)
    try Task.checkCancellation()
    day.healthDetails = healthDetails
    await saveDayInDocuments(day)
}

func fetchSettingsFromDocuments() async -> Settings {
    let filename = "settings.json"
    let url = getDocumentsDirectory().appendingPathComponent(filename)
    do {
        let data = try Data(contentsOf: url)
        let settings = try JSONDecoder().decode(Settings.self, from: data)
        return settings
    } catch {
        let settings = Settings()
        await saveSettingsInDocuments(settings)
        return settings
    }
}

func saveSettingsInDocuments(_ settings: Settings) async {
    do {
        let filename = "settings.json"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        let json = try JSONEncoder().encode(settings)
        try json.write(to: url)
    } catch {
        fatalError()
    }
}
