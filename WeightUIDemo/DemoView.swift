import SwiftUI
import SwiftSugar

let LargeNumberFont: Font = .system(.largeTitle, design: .rounded, weight: .bold)

struct DemoView: View {
    
    enum WeightFormType: Int, Hashable, Identifiable, CaseIterable {
        case weight = 1
        case weightPast
        case weightChangePoint
        case weightChangePointPast
        case sex
        case sexPast
        case age
        case agePast
        case leanBodyMass
        case leanBodyMassPast
        case height
        case heightPast

        var id: Int { rawValue }
        var label: String {
            switch self {
            case .height:
                "Height"
            case .heightPast:
                "Height (Past)"
            case .age:
                "Age"
            case .agePast:
                "Age Past"
            case .leanBodyMass:
                "Lean Body Mass"
            case .leanBodyMassPast:
                "Lean Body Mass (Past)"
            case .weight:
                "Weight"
            case .weightPast:
                "Weight (Past)"
            case .weightChangePoint:
                "Weight Change Point"
            case .weightChangePointPast:
                "Weight Change Point (Past)"
            case .sex:
                "Biological Sex"
            case .sexPast:
                "Biological Sex (Past)"
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
        case .height:
            HeightForm()
        case .heightPast:
            HeightForm_Past()
        case .age:
            AgeForm()
        case .agePast:
            AgeForm_Past()
        case .leanBodyMass:
            LeanBodyMassForm()
        case .leanBodyMassPast:
            LeanBodyMassForm_Past()
        case .sex:
            SexForm()
        case .sexPast:
            SexForm_Past()
        case .weight:
            WeightForm()
        case .weightPast:
            WeightForm_Past()
        case .weightChangePoint:
            WeightChangePointForm()
        case .weightChangePointPast:
            WeightChangePointForm_Past()
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
