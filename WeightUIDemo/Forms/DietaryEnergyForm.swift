import SwiftUI
import PrepShared

struct DietaryEnergyForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    @Bindable var healthProvider: HealthProvider
    
    let date: Date
    let initialDietaryEnergy: HealthDetails.Maintenance.Adaptive.DietaryEnergy
    
    @State var kcalsPerDay: Double?
    @State var points: [DietaryEnergyPoint]

    @State var isEditing: Bool
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    let saveHandler: (HealthDetails.Maintenance.Adaptive.DietaryEnergy) -> ()
    
    init(
        date: Date = Date.now,
        dietaryEnergy: HealthDetails.Maintenance.Adaptive.DietaryEnergy,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false),
        saveHandler: @escaping (HealthDetails.Maintenance.Adaptive.DietaryEnergy) -> ()
    ) {
        self.date = date
        self.initialDietaryEnergy = dietaryEnergy
        self.healthProvider = healthProvider
        self.saveHandler = saveHandler
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: true)
        
        _kcalsPerDay = State(initialValue: dietaryEnergy.kcalPerDay)
        _points = State(initialValue: dietaryEnergy.points)
    }

    var body: some View {
        List {
            notice
            list
            explanation
        }
        .navigationTitle("Dietary Energy")
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) { bottomValue }
    }
    
    var bottomValue: some View {
        var energyValue: Double? {
            guard let kcalsPerDay else { return nil }
            return EnergyUnit.kcal.convert(kcalsPerDay, to: settingsProvider.energyUnit)
        }

        return MeasurementBottomBar(
            double: Binding<Double?>(
                get: { energyValue },
                set: { _ in }
            ),
            doubleString: Binding<String?>(
                get: { energyValue?.formattedEnergy },
                set: { _ in }
            ),
            doubleUnitString: "\(settingsProvider.energyUnit)/day",
            isDisabled: .constant(true)
        )
    }
    
    var list: some View {
        Section {
            ForEach(points, id: \.self) { point in
                NavigationLink {
                    DietaryEnergyPointForm(
                        date: date,
                        point: point,
                        settingsProvider: settingsProvider,
                        healthProvider: healthProvider,
                        isPresented: $isPresented,
                        dismissDisabled: $dismissDisabled,
                        saveHandler: { updatedPoint in
                            updatePoint(updatedPoint, for: point.date)
                        }
                    )
                } label: {
                    DietaryEnergyCell(point: point)
                }
            }
        }
    }
    
    func updatePoint(_ point: DietaryEnergyPoint, for date: Date) {
        guard let index = points.firstIndex(where: { $0.date == date }) else {
            fatalError()
        }
        points[index] = point
        handleChanges()
    }
    
    func handleChanges() {
        points.fillAverages()
        kcalsPerDay = points.average
        save()
    }
    
    var isLegacy: Bool {
        date.startOfDay < Date.now.startOfDay
    }
    
    @ViewBuilder
    var notice: some View {
        if isLegacy {
            NoticeSection.legacy(date, isEditing: $isEditing)
        }
    }
    
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isPresented = false
            } label: {
                CloseButtonLabel()
            }
        }
    }
    
    func save() {
        saveHandler(dietaryEnergy)
    }
    
    var dietaryEnergy: HealthDetails.Maintenance.Adaptive.DietaryEnergy {
        .init(
            points: points
        )
    }
    
    func undo() {
        kcalsPerDay = initialDietaryEnergy.kcalPerDay
        points = initialDietaryEnergy.points
    }

    var explanation: some View {
        Section {
            Text("This is how much dietary energy you consumed over the period for which you are calculating your Adaptive Maintenance.")
        }
    }
}

struct DietaryEnergyPointSourceImage: View {
    
    let source: DietaryEnergyPointSource
    
    var body: some View {
        switch source {
        case .healthKit:
            Image("AppleHealthIcon")
                .resizable()
                .frame(width: 24, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(.systemGray3), lineWidth: 0.5)
                )
        case .fasted:
            Text("0")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(.label))
                .monospaced()
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(Color(.systemGray4))
                )
        default:
            Image(systemName: source.image)
                .scaleEffect(source.imageScale)
                .foregroundStyle(Color(.label))
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(Color(.systemGray4))
                )
        }
    }
}

struct DietaryEnergyCell: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    let point: DietaryEnergyPoint
    
    var body: some View {
        HStack {
            DietaryEnergyPointSourceImage(source: point.source)
//            image
            dateText
            Spacer()
            detail
        }
    }
    
//    @ViewBuilder
//    var image: some View {
//        switch point.source {
//        case .healthKit:
//            Image("AppleHealthIcon")
//                .resizable()
//                .frame(width: 24, height: 24)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 5)
//                        .stroke(Color(.systemGray3), lineWidth: 0.5)
//                )
////        case .useAverage:
////            EmptyView()
////            Color.clear
////                .frame(width: 24, height: 24)
////                .opacity(0)
//        default:
//            Image(systemName: point.source.image)
//                .frame(width: 24, height: 24)
//                .foregroundStyle(point.source.foregroundColor)
//                .background(
//                    RoundedRectangle(cornerRadius: 5)
//                        .foregroundStyle(point.source.backgroundColor)
//                )
//        }
//    }
    
    var detail: some View {
        var label: String {
            guard let kcal = point.kcal else {
                return "Not Counted"
            }
            let value = EnergyUnit.kcal.convert(kcal, to: settingsProvider.energyUnit)
            return "\(value.formattedEnergy) \(settingsProvider.energyUnit.abbreviation)"
        }
        
        var foregroundColor: Color {
            point.source == .useAverage || point.kcal == nil
            ? Color(.secondaryLabel)
            : Color(.label)
        }
        
        return Text(label)
            .foregroundStyle(foregroundColor)
    }
    
    var dateText: some View {
        Text(point.date.shortDateString)
            .foregroundStyle(Color(.label))
    }
}

//#Preview("Current") {
//    NavigationView {
//        DietaryEnergyForm()
//    }
//}
//
//#Preview("Past") {
//    NavigationView {
//        DietaryEnergyForm(date: MockPastDate)
//    }
//}


#Preview("DemoView") {
    DemoView()
}
