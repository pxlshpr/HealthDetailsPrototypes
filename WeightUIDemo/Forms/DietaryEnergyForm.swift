import SwiftUI

struct DietaryEnergyForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    @Bindable var healthProvider: HealthProvider
    
    let date: Date
    let initialDietaryEnergy: HealthDetails.Maintenance.Adaptive.DietaryEnergy
    
    @State var kcalsPerDay: Double?
    @State var points: [HealthDetails.Maintenance.Adaptive.DietaryEnergy.Point]

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
        MeasurementBottomBar(
            double: $kcalsPerDay,
            doubleString: Binding<String?>(
                get: { kcalsPerDay?.formattedEnergy },
                set: { _ in }
            ),
            doubleUnitString: "kcal/day",
            isDisabled: .constant(true)
        )
    }
    
    var list: some View {
        Section {
            ForEach(listData, id: \.self) { data in
                NavigationLink {
                    DietaryEnergyPointForm(
                        healthDetailsDate: date,
                        dietaryEnergyDate: data.date,
                        isPresented: $isPresented,
                        dismissDisabled: $dismissDisabled
                    )
                } label: {
                    DietaryEnergyCell(listData: data)
                }
            }
        }
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
        
    }
    
    func undo() {
        kcalsPerDay = 2893
    }

    var explanation: some View {
        Section {
            Text("This is how much dietary energy you consumed over the period for which you are calculating your Adaptive Maintenance.")
        }
    }
    
    struct ListData: Hashable, Identifiable {
        
        let type: DietaryEnergyPointType
        let date: Date
        let valueString: String
        
        init(_ type: DietaryEnergyPointType, _ date: Date, _ valueString: String) {
            self.type = type
            self.date = date
            self.valueString = valueString
        }
        
        var id: Date { date }
    }
    
    var listData: [ListData] {
        [
            .init(.log, date.moveDayBy(-1), "2,345 kcal"),
            .init(.log, date.moveDayBy(-2), "3,012 kcal"),
            .init(.custom, date.moveDayBy(-3), "0 kcal"),
            .init(.useAverage, date.moveDayBy(-4), "1,983 kcal"),
            .init(.healthKit, date.moveDayBy(-5), "1,725 kcal"),
            .init(.useAverage, date.moveDayBy(-6), "1,983 kcal"),
            .init(.log, date.moveDayBy(-7), "2,831 kcal"),
        ]
    }
}

struct DietaryEnergyCell: View {
    
    let listData: DietaryEnergyForm.ListData
    var body: some View {
        HStack {
            image
            dateText
            Spacer()
            detail
        }
    }
    
    @ViewBuilder
    var image: some View {
        switch listData.type {
        case .healthKit:
            Image("AppleHealthIcon")
                .resizable()
                .frame(width: 24, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(.systemGray3), lineWidth: 0.5)
                )
//        case .useAverage:
//            EmptyView()
//            Color.clear
//                .frame(width: 24, height: 24)
//                .opacity(0)
        default:
            Image(systemName: listData.type.image)
                .frame(width: 24, height: 24)
                .foregroundStyle(listData.type.foregroundColor)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(listData.type.backgroundColor)
                )
        }
    }
    
    @ViewBuilder
    var detail: some View {
        if listData.type == .useAverage {
//            Text("Not Included")
//            Text("Exclude and Use Average")
            Text("2,235 kcal")
//                .foregroundStyle(Color(.label))
                .foregroundStyle(Color(.secondaryLabel))
        } else {
            Text(listData.valueString)
                .foregroundStyle(Color(.label))
        }
    }
    
    var dateText: some View {
        Text(listData.date.shortDateString)
            .foregroundStyle(Color(.label))
    }
}


#Preview("Current") {
    NavigationView {
        DietaryEnergyForm()
    }
}

#Preview("Past") {
    NavigationView {
        DietaryEnergyForm(date: MockPastDate)
    }
}

#Preview("DemoView") {
    DemoView()
}
