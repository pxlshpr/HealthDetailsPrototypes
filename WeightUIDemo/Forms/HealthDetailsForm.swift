import SwiftUI

struct HealthDetailsForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    @Bindable var healthProvider: HealthProvider
    
    @Binding var isPresented: Bool
    @State var dismissDisabled: Bool = false
    
    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool>
    ) {
        self.healthProvider = healthProvider
        _isPresented = isPresented
    }
    
    var pastDate: Date? {
        healthProvider.pastDate
    }
    
    var body: some View {
        NavigationView {
            form
                .navigationTitle("Health Details")
                .navigationBarTitleDisplayMode(.large)
        }
        .interactiveDismissDisabled(dismissDisabled)
    }
    
    var form: some View {
        Form {
            dateSection
            Section {
                link(for: .maintenance)
            }
            Section {
                link(for: .weight)
                link(for: .leanBodyMass)
                link(for: .height)
            }
            Section {
                link(for: .age)
                link(for: .sex)
                link(for: .smokingStatus)
                link(for: .preganancyStatus)
            }
        }
    }
    
    func link(for healthDetail: HealthDetail) -> some View {
        NavigationLink {
            sheet(for: healthDetail)
        } label: {
            Text(healthDetail.name)
        }
    }
    
    @ViewBuilder
    var dateSection: some View {
        if let pastDate {
            Section {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(pastDate.shortDateString)
                }
            }
        }
    }
    
    @ViewBuilder
    func sheet(for route: HealthDetail) -> some View {
        switch route {
        case .maintenance:
            MaintenanceForm(
                healthProvider: healthProvider,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        case .leanBodyMass:
            LeanBodyMassForm(
                healthProvider: healthProvider,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        case .weight:
            WeightForm(
                healthProvider: healthProvider,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        case .height:
            HeightForm(
                healthProvider: healthProvider,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        case .age:
            AgeForm(
                healthProvider: healthProvider,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        case .sex:
            BiologicalSexForm(
                healthProvider: healthProvider,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        case .preganancyStatus:
            PregnancyStatusForm(
                healthProvider: healthProvider,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        case .smokingStatus:
            SmokingStatusForm(
                healthProvider: healthProvider,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        }
    }
}

#Preview("Current") {
    MockCurrentHealthDetailsForm()
}

#Preview("Past") {
    MockPastHealthDetailsForm()
}
