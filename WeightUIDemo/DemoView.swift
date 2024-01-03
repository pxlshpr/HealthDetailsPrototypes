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
        }
        .sheet(item: $pastDateBeingShown) { date in
            MockHealthDetailsForm(
                date: date,
                isPresented: Binding<Bool>(
                    get: { true },
                    set: { if !$0 { pastDateBeingShown = nil } }
                )
            )
            .environment(settingsProvider)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsForm(settingsProvider, isPresented: $showingSettings)
        }
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
