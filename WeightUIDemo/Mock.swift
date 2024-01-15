import SwiftUI

public var isPreview: Bool {
    return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

var CurrentHealthDetails: HealthDetails {
    fetchOrCreateHealthDetailsFromDocuments(Date.now)
}

struct MockHealthDetailsForm: View {
    
    @Bindable var settingsProvider: SettingsProvider

    @State var healthProvider: HealthProvider
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
        
        let healthDetails = fetchOrCreateHealthDetailsFromDocuments(date)
        let healthProvider = HealthProvider(
            healthDetails: healthDetails,
            settingsProvider: settingsProvider
        )
        _healthProvider = State(initialValue: healthProvider)
    }

    var body: some View {
        HealthDetailsForm(
            healthProvider: healthProvider,
            isPresented: $isPresented
        )
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

struct Day: Codable, Hashable {
    let date: Date
    var healthDetails: HealthDetails
    var dietaryEnergyPoint: DietaryEnergyPoint?
    var energyInKcal: Double?
    
    init(date: Date) {
        self.date = date
        self.healthDetails = HealthDetails(date: date)
    }
}

func fetchOrCreateDayFromDocuments(_ date: Date) -> Day {
    let filename = "\(date.dateString).json"
    let url = getDocumentsDirectory().appendingPathComponent(filename)
    do {
        let data = try Data(contentsOf: url)
        let day = try JSONDecoder().decode(Day.self, from: data)
        return day
    } catch {
        let day = Day(date: date)
        saveDayInDocuments(day)
        return day
    }
}

func fetchAllDaysFromDocuments(
    from startDate: Date,
    createIfNotExisting: Bool
) async -> [Day] {
    //TODO: In production:
    /// [ ] Optimizing by not fetching the meals etc, only fetching fields we need
    var days: [Day] = []
    for i in (0...Date.now.numberOfDaysFrom(startDate)).reversed() {
        let date = Date.now.moveDayBy(-i)
        let day = if createIfNotExisting {
            fetchOrCreateDayFromDocuments(date)
        } else {
            fetchDayFromDocuments(date)
        }
        if let day {
            days.append(day)
        }
    }
    return days
}

func fetchDayFromDocuments(_ date: Date) -> Day? {
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

func saveDayInDocuments(_ day: Day) {
    do {
        let filename = "\(day.date.dateString).json"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        let json = try JSONEncoder().encode(day)
        try json.write(to: url)
    } catch {
        fatalError()
    }
}

func fetchOrCreateHealthDetailsFromDocuments(_ date: Date) -> HealthDetails {
    fetchOrCreateDayFromDocuments(date).healthDetails
}

func fetchHealthDetailsFromDocuments(_ date: Date) -> HealthDetails? {
    fetchDayFromDocuments(date)?.healthDetails
}

func saveHealthDetailsInDocuments(_ healthDetails: HealthDetails) {
    var day = fetchOrCreateDayFromDocuments(healthDetails.date)
    day.healthDetails = healthDetails
    saveDayInDocuments(day)
}

func fetchSettingsFromDocuments() -> Settings {
    let filename = "settings.json"
    let url = getDocumentsDirectory().appendingPathComponent(filename)
    do {
        let data = try Data(contentsOf: url)
        let settings = try JSONDecoder().decode(Settings.self, from: data)
        return settings
    } catch {
        let settings = Settings()
        saveSettingsInDocuments(settings)
        return settings
    }
}

func saveSettingsInDocuments(_ settings: Settings) {
    do {
        let filename = "settings.json"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        let json = try JSONEncoder().encode(settings)
        try json.write(to: url)
    } catch {
        fatalError()
    }
}
