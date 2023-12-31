import SwiftUI

struct MockCurrentHealthDetailsForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider

    @State var healthProvider: HealthProvider
    @Binding var isPresented: Bool

    init(isPresented: Binding<Bool> = .constant(true)) {
        _isPresented = isPresented
        
        let healthDetails = fetchHealthDetailsFromDocuments(Date.now)
        let healthProvider = HealthProvider(isCurrent: true, healthDetails: healthDetails)
        _healthProvider = State(initialValue: healthProvider)
    }

    var body: some View {
        HealthDetailsForm(healthProvider: healthProvider, isPresented: $isPresented)
            .environment(settingsProvider)
    }
}

struct MockPastHealthDetailsForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider

    @State var healthProvider: HealthProvider
    @Binding var isPresented: Bool
    
    init(isPresented: Binding<Bool> = .constant(true)) {
        _isPresented = isPresented
        
        let healthDetails = fetchHealthDetailsFromDocuments(Date(fromDateString: "2023_12_01")!)
        let healthProvider = HealthProvider(isCurrent: false, healthDetails: healthDetails)
        _healthProvider = State(initialValue: healthProvider)        
    }

    var body: some View {
        HealthDetailsForm(healthProvider: healthProvider, isPresented: $isPresented)
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
        print("Fetching HealthDetails from documents: \(filename)")
        let data = try Data(contentsOf: url)
        let healthDetails = try JSONDecoder().decode(HealthDetails.self, from: data)
        return healthDetails
    } catch {
        print("Couldn't fetch, creating")
        let healthDetails = HealthDetails(date: date)
        saveHealthDetailsInDocuments(healthDetails)
        return healthDetails
    }
}

func saveHealthDetailsInDocuments(_ healthDetails: HealthDetails) {
    do {
        let filename = "\(healthDetails.date.dateString).json"
        print("Saving HealthDetails to documents: \(filename)")
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        let json = try JSONEncoder().encode(healthDetails)
        try json.write(to: url)
    } catch {
        print("Error Saving HealthDetails to documents")
        fatalError()
    }
}

func fetchSettingsFromDocuments() -> Settings {
    let filename = "settings.json"
    let url = getDocumentsDirectory().appendingPathComponent(filename)
    do {
        print("Fetching Settings from documents: \(filename)")
        let data = try Data(contentsOf: url)
        let settings = try JSONDecoder().decode(Settings.self, from: data)
        return settings
    } catch {
        print("Couldn't fetch, creating")
        let settings = Settings()
        saveSettingsInDocuments(settings)
        return settings
    }
}

func saveSettingsInDocuments(_ settings: Settings) {
    do {
        let filename = "settings.json"
        print("Saving Settings to documents: \(filename)")
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        let json = try JSONEncoder().encode(settings)
        try json.write(to: url)
    } catch {
        print("Error Saving Settings to documents")
        fatalError()
    }
}