import SwiftUI

struct HealthDetails: View {
    
    let pastDate: Date?
    @State var presentedHealthDetail: HealthDetail? = nil
    
    @Binding var isPresented: Bool
    
    @State var dismissDisabled: Bool = false
    
    init(pastDate: Date? = nil, isPresented: Binding<Bool> = .constant(false)) {
        self.pastDate = pastDate
        _isPresented = isPresented
    }
    
    var body: some View {
        NavigationView {
            form
                .navigationTitle("Health Details")
                .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $presentedHealthDetail) { route in
            sheet(for: route)
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
            }
            Section {
                link(for: .height)
            }
            Section {
                link(for: .age)
                link(for: .sex)
            }
            Section {
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
                pastDate: pastDate,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        case .leanBodyMass:
            LeanBodyMassForm(
                pastDate: pastDate,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        case .weight:
            WeightForm(
                pastDate: pastDate,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        case .height:
            HeightForm(
                pastDate: pastDate,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        case .age:
            AgeForm(
                pastDate: pastDate,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        default:
            EmptyView()
        }
    }
    
    func isPresentedBinding(for healthDetail: HealthDetail) -> Binding<Bool> {
        Binding<Bool>(
            get: { presentedHealthDetail == healthDetail },
            set: {
                switch $0 {
                case true: 
                    break
                case false:
                    presentedHealthDetail = nil
                }
            }
        )
    }
}

#Preview("Current") {
    HealthDetails()
}

#Preview("Past") {
    HealthDetails(pastDate: MockPastDate)
}
