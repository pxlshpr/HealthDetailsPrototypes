import SwiftUI

enum HealthDetail: Int, Identifiable, CaseIterable {
    case maintenance = 1
    var id: Int { rawValue }
    var name: String {
        switch self {
        case .maintenance:  "Maintenance Energy"
        }
    }
}


struct HealthDetails: View {
    
    let pastDate: Date?
    @State var presentedHealthDetail: HealthDetail? = nil
    
    init(pastDate: Date? = nil) {
        self.pastDate = pastDate
    }
    
    var body: some View {
        NavigationStack {
            Form {
                dateSection
                ForEach(HealthDetail.allCases) { healthDetail in
                    Button(healthDetail.name) {
                        presentedHealthDetail = healthDetail
                    }
                }
            }
            .navigationTitle("Health Details")
        }
        .sheet(item: $presentedHealthDetail) { route in
            sheet(for: route)
        }
    }
    
    @ViewBuilder
    var dateSection: some View {
        if let pastDate {
            Section {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(pastDate.dateString)
                }
            }
        }
    }
    
    @ViewBuilder
    func sheet(for route: HealthDetail) -> some View {
        switch route {
        case .maintenance:
            MaintenanceForm(pastDate: pastDate, isPresented: isPresentedBinding(for: route))
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
