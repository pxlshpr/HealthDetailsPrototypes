import SwiftUI
import PrepShared

struct DietaryEnergyForm: View {
    
    @Binding var isPresented: Bool
    @Bindable var healthProvider: HealthProvider
    
    let date: Date
    
    @State var kcalsPerDay: Double?
    @State var points: [DietaryEnergyPoint]

    let saveHandler: (HealthDetails.Maintenance.Adaptive.DietaryEnergy) -> ()
    
    init(
        date: Date = Date.now,
        dietaryEnergy: HealthDetails.Maintenance.Adaptive.DietaryEnergy,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        saveHandler: @escaping (HealthDetails.Maintenance.Adaptive.DietaryEnergy) -> ()
    ) {
        self.date = date
        self.healthProvider = healthProvider
        self.saveHandler = saveHandler
        _isPresented = isPresented
        
        _kcalsPerDay = State(initialValue: dietaryEnergy.kcalPerDay)
        _points = State(initialValue: dietaryEnergy.points)
    }

    var body: some View {
        List {
            dateSection
            list
            explanation
        }
        .navigationTitle("Total Dietary Energy")
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) { bottomValue }
    }
    
    var energyUnit: EnergyUnit { healthProvider.settingsProvider.energyUnit }
    
    var bottomValue: some View {
        var energyValue: Double? {
            guard let kcalsPerDay else { return nil }
            return EnergyUnit.kcal.convert(kcalsPerDay, to: energyUnit)
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
            doubleUnitString: "\(energyUnit.abbreviation)/day"
        )
    }
    
    var list: some View {
        Section {
            ForEach(points, id: \.self) { point in
                NavigationLink {
                    DietaryEnergyPointForm(
                        date: date,
                        point: point,
                        healthProvider: healthProvider,
                        isPresented: $isPresented,
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
    
    var dateSection: some View {
        Section {
            HStack {
                Text("Date")
                Spacer()
                Text(date.shortDateString)
            }
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
    
    var explanation: some View {
        Section {
            Text("This is how much dietary energy you consumed over the period for which you are calculating your Adaptive Maintenance.")
        }
    }
}

#Preview("DemoView") {
    DemoView()
}
