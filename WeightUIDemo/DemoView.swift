import SwiftUI
import SwiftSugar

let LargeNumberFont: Font = .system(.largeTitle, design: .rounded, weight: .bold)
let PreviousMockDate = Date(fromDateString: "2023_12_01")!

struct DemoView: View {
    
    @State var settingsProvider: SettingsProvider
    
    @State var pastDateBeingShown: Date? = nil
    @State var showingSettings = false

    init() {
        let settings = fetchSettingsFromDocuments()
        let settingsProvider = SettingsProvider(settings: settings)
        _settingsProvider = State(initialValue: settingsProvider)
    }
    
    var body: some View {
        NavigationView {
            List {
                settingsSection
                healthDetailsSection
            }
            .navigationTitle("Demo")
            .toolbar { toolbarContent }
        }
        .sheet(item: $pastDateBeingShown) { healthDetailsForm(for: $0) }
        .sheet(isPresented: $showingSettings) { settingsForm }
    }
    
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Clear Data") {
                    deleteAllFilesInDocuments()
                }
                Button("Reset Current") {
                    setCurrentHealthDetails()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    func setCurrentHealthDetails() {
        deleteAllFilesInDocuments()
        var healthDetails = fetchHealthDetailsFromDocuments(Date.now)
        healthDetails.dateOfBirth = Date(fromDateString: "1987_06_04")!
        healthDetails.biologicalSex = .male
        healthDetails.weight = .init(
            weightInKg: 96.2,
            dailyValueType: .average,
            measurements: [.init(date: Date.now, weightInKg: 96.2)],
            deletedHealthKitMeasurements: [],
            isSynced: false
        )
        healthDetails.height = .init(
            heightInCm: 177,
            measurements: [.init(date: Date.now, heightInCm: 177)],
            deletedHealthKitMeasurements: [],
            isSynced: false
        )
        healthDetails.leanBodyMass = .init(
            leanBodyMassInKg: 75.2,
            fatPercentage: 21.8,
            dailyValueType: .average,
            measurements: [.init(
                date: Date.now,
                leanBodyMassInKg: 75.2,
                fatPercentage: 21.8,
                source: .fatPercentage)
            ],
            deletedHealthKitMeasurements: [],
            isSynced: false
        )
        saveHealthDetailsInDocuments(healthDetails)
    }
    
    var settingsForm: some View {
        SettingsForm(settingsProvider, isPresented: $showingSettings)
    }
    
    func healthDetailsForm(for date: Date) -> some View {
        MockHealthDetailsForm(
            date: date,
            isPresented: Binding<Bool>(
                get: { true },
                set: { if !$0 { pastDateBeingShown = nil } }
            )
        )
        .environment(settingsProvider)
    }
    
    var healthDetailsSection: some View {

        let numberOfDays = Date.now.numberOfDaysFrom(PreviousMockDate)
        
        func button(daysAgo: Int) -> some View {
            let date = Date.now.moveDayBy(-daysAgo)
            return Button {
                pastDateBeingShown = date
            } label: {
                Text(date.shortDateString + "\(daysAgo == 0 ? " (Current)" : "")")
            }
        }
        
        return Section("Health Details") {
            ForEach(0...numberOfDays, id: \.self) {
                button(daysAgo: $0)
            }
        }
    }
    
    var settingsSection: some View {
        Section {
            Button {
                showingSettings = true
            } label: {
                Text("Settings")
            }
        }
    }
}

#Preview("DemoView") {
    DemoView()
}

let MockPastDate = Date.now.moveDayBy(-3)

func valueForActivityLevel(_ activityLevel: ActivityLevel) -> Double {
    switch activityLevel {
    case .sedentary:            2442
    case .lightlyActive:        2798.125
    case .moderatelyActive:     3154.25
    case .active:               3510.375
    case .veryActive:           3866.5
    }
}

extension Date: Identifiable {
    public var id: Date { return self }
}
