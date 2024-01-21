import SwiftUI
import SwiftSugar
import PrepShared

struct WeightForm: View {
    
    @Bindable var healthProvider: HealthProvider

    let date: Date
    
    @State var weightInKg: Double?
    @State var measurements: [WeightMeasurement]
    @State var deletedHealthKitMeasurements: [WeightMeasurement]

    @State var dailyMeasurementType: DailyMeasurementType
    @State var isSynced: Bool = true

    @State var showingForm = false
    
    @Binding var isPresented: Bool
    
    let saveHandler: (HealthDetails.Weight) -> ()
    
    init(
        date: Date,
        weight: HealthDetails.Weight,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        save: @escaping (HealthDetails.Weight) -> ()
    ) {
        self.date = date
        self.saveHandler = save
        self.healthProvider = healthProvider
        _isPresented = isPresented

        _weightInKg = State(initialValue: weight.weightInKg)
        _measurements = State(initialValue: weight.measurements)
        _deletedHealthKitMeasurements = State(initialValue: weight.deletedHealthKitMeasurements)

        _dailyMeasurementType = State(initialValue: healthProvider.settingsProvider.settings.dailyMeasurementType(for: .weight))
        _isSynced = State(initialValue: healthProvider.settingsProvider.weightIsHealthKitSynced)
    }
    
    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            weight: healthProvider.healthDetails.weight,
            healthProvider: healthProvider,
            isPresented: isPresented,
            save: healthProvider.saveWeight
        )
    }
    
    var body: some View {
        Form {
            dateSection
            measurementsSections
            dailyMeasurementTypePicker
            syncSection
            explanation
        }
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingForm) { measurementForm }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .onChange(of: isSynced, isSyncedChanged)
    }
    
    func isSyncedChanged(old: Bool, new: Bool) {
        healthProvider.setHealthKitSyncing(for: .weight, to: new)
    }

    var explanation: some View {
        var header: some View {
            Text("Usage")
        }
        return Section(header: header) {
            VStack(alignment: .leading) {
                Text("Your weight is used when:")
                dotPoint("Creating goals. For example, you could create a protein goal relative to your weight.")
                dotPoint("Calculating your Adaptive Maintenance Energy, Resting Energy, or Lean Body Mass.")
            }
        }
    }
    
    var measurementsSections: some View {
        MeasurementsSections<BodyMassUnit>(
            settingsProvider: healthProvider.settingsProvider,
            measurements: Binding<[any Measurable]>(
                get: { measurements },
                set: { newValue in
                    guard let measurements = newValue as? [WeightMeasurement] else { return }
                    self.measurements = measurements
                }
            ),
            deletedHealthKitMeasurements: Binding<[any Measurable]>(
                get: { deletedHealthKitMeasurements },
                set: { newValue in
                    guard let measurements = newValue as? [WeightMeasurement] else { return }
                    self.deletedHealthKitMeasurements = measurements
                }
            ),
            showingForm: $showingForm,
            handleChanges: handleChanges
        )
    }
    
    var bodyMassUnit: BodyMassUnit { healthProvider.settingsProvider.bodyMassUnit }

    var measurementForm: some View {
        MeasurementForm(
            type: .weight,
            date: date,
            settingsProvider: healthProvider.settingsProvider
        ) { int, double, time in
            let weightInKg = bodyMassUnit.convert(int, double, to: .kg)
            let measurement = WeightMeasurement(date: time, weightInKg: weightInKg)
            measurements.append(measurement)
            measurements.sort()
            handleChanges()
        }
    }


    var bottomValue: some View {
        var intUnitString: String? { bodyMassUnit.intUnitString }
        var doubleUnitString: String { bodyMassUnit.doubleUnitString }
        
        var double: Double? {
            guard let weightInKg else { return nil }
            return BodyMassUnit.kg
                .doubleComponent(weightInKg, in: bodyMassUnit)
        }
        
        var int: Int? {
            guard let weightInKg else { return nil }
            return BodyMassUnit.kg
                .intComponent(weightInKg, in: bodyMassUnit)
        }
        
        return MeasurementBottomBar(
            int: Binding<Int?>(
                get: { int }, set: { _ in }
            ),
            intUnitString: intUnitString,
            double: Binding<Double?>(
                get: { double }, set: { _ in }
            ),
            doubleString: Binding<String?>(
                get: { double?.cleanHealth }, set: { _ in }
            ),
            doubleUnitString: doubleUnitString
        )
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

    var dailyMeasurementTypePicker: some View {
        let binding = Binding<DailyMeasurementType>(
            get: { dailyMeasurementType },
            set: { newValue in
                withAnimation {
                    dailyMeasurementType = newValue
                    healthProvider.setDailyMeasurementType(for: .weight, to: newValue)
                    handleChanges()
                }
            }
        )
        
        var pickerRow: some View {
            Picker("", selection: binding) {
                ForEach(DailyMeasurementType.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
        }

        var description: String {
            dailyMeasurementType.description(for: .weight)
        }

        var header: some View {
            Text("Handling Multiple Measurements")
        }

        return Section(header: header) {
            pickerRow
            Text(description)
        }
    }

    var syncSection: some View {
        SyncSection(
            healthDetail: .weight,
            isSynced: $isSynced,
            handleChanges: handleChanges
        )
    }
    
    func handleChanges() {
        weightInKg = calculatedWeightInKg
        save()
    }

    func save() {
        saveHandler(weight)
    }

    var calculatedWeightInKg: Double? {
        measurements.dailyMeasurement(for: dailyMeasurementType)
    }

    var weight: HealthDetails.Weight {
        HealthDetails.Weight(
            weightInKg: calculatedWeightInKg,
            measurements: measurements,
            deletedHealthKitMeasurements: deletedHealthKitMeasurements
        )
    }
}

#Preview("Demo") {
    DemoView()
}
