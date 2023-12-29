import SwiftUI

enum HealthDetail: Int, Identifiable, CaseIterable {
    case maintenance = 1
    
    case age
    case sex
    case weight
    case leanBodyMass
    case height
    
    var id: Int { rawValue }
    var name: String {
        switch self {
        case .maintenance:  "Maintenance Energy"
        case .age: "Age"
        case .sex: "Sex"
        case .height: "Height"
        case .weight: "Weight"
        case .leanBodyMass: "Lean Body Mass"
        }
    }
    
    var isCharacteristic: Bool {
        switch self {
        case .age, .sex: true
        default: false
        }
    }
    
    var isMeasurement: Bool {
        switch self {
        case .height, .weight, .leanBodyMass: true
        default: false
        }
    }
}

extension HealthDetail: Comparable {
    static func < (lhs: HealthDetail, rhs: HealthDetail) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension Array where Element == HealthDetail {
    var characteristics: [HealthDetail] {
        filter{ $0.isCharacteristic }.sorted()
    }
    
    var measurements: [HealthDetail] {
        filter{ $0.isMeasurement }.sorted()
    }
}

struct HealthDetails: View {
    
    let pastDate: Date?
    @State var presentedHealthDetail: HealthDetail? = nil
    
    @Binding var isPresented: Bool
    
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
    }
    
    var form: some View {
        Form {
            dateSection
            ForEach(HealthDetail.allCases) { healthDetail in
                NavigationLink {
                    sheet(for: healthDetail)
                } label: {
                    Text(healthDetail.name)
                }
//                Button(healthDetail.name) {
//                    presentedHealthDetail = healthDetail
//                }
            }
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
            MaintenanceForm(pastDate: pastDate, isPresented: $isPresented)
        case .leanBodyMass:
            LeanBodyMassForm(pastDate: pastDate, isPresented: $isPresented)
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
