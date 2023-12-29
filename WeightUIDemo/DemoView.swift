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
        NavigationView {
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
            HealthDetails(isPresented: Binding<Bool>(
                get: { self.type == .maintenance },
                set: { newValue in
                    if !newValue {
                        self.type = nil
                    }
                }
            ))
        case .pastMaintenance:
            HealthDetails(pastDate: MockPastDate, isPresented: Binding<Bool>(
                get: { self.type == .pastMaintenance },
                set: { newValue in
                    if !newValue {
                        self.type = nil
                    }
                }
            ))
        }
    }
}

#Preview {
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
