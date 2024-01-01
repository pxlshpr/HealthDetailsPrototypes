import SwiftUI

var CurrentHealthDetails: HealthDetails {
    fetchHealthDetailsFromDocuments(Date.now)
}
var PreviousHealthDetails: HealthDetails {
    fetchHealthDetailsFromDocuments(Date(fromDateString: "2023_12_01")!)
}

struct MockCurrentHealthDetailsForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider

    @State var healthProvider: HealthProvider
    @Binding var isPresented: Bool

    init(isPresented: Binding<Bool> = .constant(true)) {
        _isPresented = isPresented
        
        var latest = HealthProvider.LatestHealthDetails()
        latest.weight = .init(
            date: PreviousHealthDetails.date,
            weight: PreviousHealthDetails.weight
        )
        latest.height = .init(
            date: PreviousHealthDetails.date,
            height: PreviousHealthDetails.height
        )
        
        let healthProvider = HealthProvider(
            isCurrent: true,
            healthDetails: CurrentHealthDetails,
            latest: latest
        )
        _healthProvider = State(initialValue: healthProvider)
    }

    var body: some View {
        HealthDetailsForm(
            healthProvider: healthProvider,
            isPresented: $isPresented
        )
        .environment(settingsProvider)
    }
}

struct MockPastHealthDetailsForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider

    @State var healthProvider: HealthProvider
    @Binding var isPresented: Bool
    
    init(isPresented: Binding<Bool> = .constant(true)) {
        _isPresented = isPresented
        
        let healthProvider = HealthProvider(
            isCurrent: false,
            healthDetails: PreviousHealthDetails
        )
        _healthProvider = State(initialValue: healthProvider)
    }

    var body: some View {
        HealthDetailsForm(
            healthProvider: healthProvider,
            isPresented: $isPresented
        )
        .environment(settingsProvider)
    }
}


let MockCurrentProvider = HealthProvider(
    isCurrent: true,
    healthDetails: HealthDetails(
        date: Date.now,
        sex: .notSet
    )
)

let MockPastProvider = HealthProvider(
    isCurrent: false,
    healthDetails: HealthDetails(
        date: Date.now.moveDayBy(-1),
        sex: .male,
        age: .init(years: 20),
        smokingStatus: .nonSmoker,
        pregnancyStatus: .notSet
    )
)

//MARK: Reusable

func getDocumentsDirectory() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}

func fetchHealthDetailsFromDocuments(_ date: Date) -> HealthDetails {
    let filename = "\(date.dateString).json"
    let url = getDocumentsDirectory().appendingPathComponent(filename)
    do {
        let data = try Data(contentsOf: url)
        let healthDetails = try JSONDecoder().decode(HealthDetails.self, from: data)
        return healthDetails
    } catch {
        let healthDetails = HealthDetails(date: date)
        saveHealthDetailsInDocuments(healthDetails)
        return healthDetails
    }
}

func saveHealthDetailsInDocuments(_ healthDetails: HealthDetails) {
    do {
        let filename = "\(healthDetails.date.dateString).json"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        let json = try JSONEncoder().encode(healthDetails)
        try json.write(to: url)
    } catch {
        fatalError()
    }
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
