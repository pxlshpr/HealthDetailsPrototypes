import SwiftUI
import SwiftSugar

let LargeNumberFont: Font = .system(.largeTitle, design: .rounded, weight: .bold)

struct DemoView: View {
    
    @State var settingsProvider: SettingsProvider
    
    @State var showingCurrentHealthDetails = false
    @State var showingPastHealthDetails = false
    @State var showingSettings = false

    init() {
        let settings = fetchSettingsFromDocuments()
        let settingsProvider = SettingsProvider(settings: settings)
        _settingsProvider = State(initialValue: settingsProvider)
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button {
                        showingCurrentHealthDetails = true
                    } label: {
                        Text("Health Details")
                    }
                    
                    Button {
                        showingPastHealthDetails = true
                    } label: {
                        Text("Health Details (Past)")
                    }
                }
                
                Section {
                    Button {
                        showingSettings = true
                    } label: {
                        Text("Settings")
                    }
                }
            }
            .navigationTitle("Demo")
        }
        .sheet(isPresented: $showingCurrentHealthDetails) {
            MockCurrentHealthDetailsForm(isPresented: $showingCurrentHealthDetails)
                .environment(settingsProvider)
        }
        .sheet(isPresented: $showingPastHealthDetails) {
            MockPastHealthDetailsForm(isPresented: $showingPastHealthDetails)
                .environment(settingsProvider)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsForm(settingsProvider, isPresented: $showingSettings)
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
