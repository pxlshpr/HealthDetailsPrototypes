import SwiftUI
import SwiftSugar

let LargeNumberFont: Font = .system(.largeTitle, design: .rounded, weight: .bold)

struct DemoView: View {
    
    enum WeightFormType: Int, Hashable, Identifiable, CaseIterable {
        case maintenance = 1
        case pastMaintenance

        var id: Int { rawValue }
        var label: String {
            switch self {
            case .maintenance:
                "Health Details"
            case .pastMaintenance:
                "Health Details (Past)"
            }
        }
    }
    
    @State var type: WeightFormType? = nil
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(WeightFormType.allCases) { type in
                    Button {
                        self.type = type
                    } label: {
                        Text(type.label)
                    }
                }
            }
            .navigationTitle("Demo")
        }
        .sheet(item: $type) { type in
            sheet(for: type)
        }
    }
    
    @ViewBuilder
    func sheet(for type: WeightFormType) -> some View {
        switch type {
        case .maintenance:
            HealthDetails()
        case .pastMaintenance:
            HealthDetails(pastDate: MockPastDate)
        }
    }
}

public extension Date {
    var dateString: String {
        let formatter = DateFormatter()
        if self.year == Date().year {
            formatter.dateFormat = "d MMM"
        } else {
            formatter.dateFormat = "d MMM yyyy"
        }
        return formatter.string(from: self)
    }
}

#Preview {
    DemoView()
//    WeightForm()
//    SampleWeightForm()
}
