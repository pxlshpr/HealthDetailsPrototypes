import SwiftUI
import SwiftSugar
import PrepShared

struct WeightForm: View {
    
    @Bindable var healthProvider: HealthProvider

    let date: Date
    let initialWeight: HealthDetails.Weight
    
    @State var weightInKg: Double?
    @State var dailyValueType: DailyValueType
    @State var measurements: [WeightMeasurement]
    @State var deletedHealthKitMeasurements: [WeightMeasurement]
    @State var isSynced: Bool = true

    @State var showingForm = false
    
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool
    
    let saveHandler: (HealthDetails.Weight) -> ()
    
    init(
        date: Date,
        weight: HealthDetails.Weight,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false),
        save: @escaping (HealthDetails.Weight) -> ()
    ) {
        self.date = date
        self.initialWeight = weight
        self.saveHandler = save
        self.healthProvider = healthProvider
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
//        _isEditing = State(initialValue: date.isToday)
        _isEditing = State(initialValue: true)

        _weightInKg = State(initialValue: weight.weightInKg)
        _measurements = State(initialValue: weight.measurements)
        _dailyValueType = State(initialValue: weight.dailyValueType)
        _deletedHealthKitMeasurements = State(initialValue: weight.deletedHealthKitMeasurements)
        _isSynced = State(initialValue: healthProvider.settingsProvider.weightIsHealthKitSynced)
    }
    
    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            weight: healthProvider.healthDetails.weight,
            healthProvider: healthProvider,
            isPresented: isPresented,
            dismissDisabled: dismissDisabled,
            save: healthProvider.saveWeight
        )
    }
    
    var body: some View {
        Form {
            noticeOrDateSection
            measurementsSections
            dailyValuePicker
            syncSection
            explanation
        }
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingForm) { measurementForm }
        .safeAreaInset(edge: .bottom) { bottomValue }
//        .navigationBarBackButtonHidden(isLegacy && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
        .onChange(of: isSynced, isSyncedChanged)
    }
    
    func isSyncedChanged(old: Bool, new: Bool) {
        healthProvider.setHealthKitSyncing(for: .weight, to: new)
    }

    var explanation: some View {
        var header: some View {
            Text("Usage")
//                .formTitleStyle()
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
            isPast: Binding<Bool>(
                get: { isLegacy },
                set: { _ in }
            ),
            isEditing: Binding<Bool>(
                get: { isEditing },
                set: { _ in }
            ),
//            dailyValueType: $dailyValueType,
            handleChanges: handleChanges
        )
    }
    
    var bodyMassUnit: BodyMassUnit { healthProvider.settingsProvider.bodyMassUnit }

    var measurementForm: some View {
        MeasurementForm(
            type: .weight,
            date: date
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
            doubleUnitString: doubleUnitString,
            isDisabled: Binding<Bool>(
                get: { isDisabled }, set: { _ in }
            )
        )
    }
    
    @ViewBuilder
    var noticeOrDateSection: some View {
//        if isLegacy {
        if date.startOfDay < Date.now.startOfDay {
            NoticeSection.legacy(date, isEditing: $isEditing)
        } else {
            Section {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(date.shortDateString)
                }
            }
        }
    }
    
    var dailyValuePicker: some View {
        let binding = Binding<DailyValueType>(
            get: { dailyValueType },
            set: { newValue in
                withAnimation {
                    dailyValueType = newValue
                    handleChanges()
                }
            }
        )
        
        var pickerRow: some View {
            Picker("", selection: binding) {
                ForEach(DailyValueType.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
            .disabled(isDisabled)
        }

        var description: String {
            dailyValueType.description
        }

        var header: some View {
            Text("Handling Multiple Measurements")
        }

        return Section(header: header) {
            pickerRow
            Text(description)
        }
    }

    @ViewBuilder
    var syncSection: some View {
        if !isLegacy {
            SyncSection(
                healthDetail: .weight,
                isSynced: $isSynced,
                handleChanges: handleChanges
            )
        }
    }
    
    var toolbarContent: some ToolbarContent {
        topToolbarContent(
            isEditing: $isEditing,
            isDirty: $isDirty,
            isPast: isLegacy,
            dismissAction: { isPresented = false },
            undoAction: undo,
            saveAction: save
        )
    }
    
    //MARK: - Actions
    
    func setIsDirty() {
        isDirty = weight != initialWeight
    }
    
    func setDismissDisabled() {
        dismissDisabled = isLegacy && isEditing && isDirty
    }

    func handleChanges() {
        weightInKg = calculatedWeightInKg
        setIsDirty()
        if !isLegacy {
            save()
        }
    }

    func undo() {
        self.weightInKg = initialWeight.weightInKg
        self.dailyValueType = initialWeight.dailyValueType
        self.measurements = initialWeight.measurements
        self.deletedHealthKitMeasurements = initialWeight.deletedHealthKitMeasurements
    }
    
    func save() {
        saveHandler(weight)
    }

    //MARK: - Convenience
    
    var isDisabled: Bool {
        isLegacy && !isEditing
    }
    
    var controlColor: Color {
        isDisabled ? .secondary : .primary
    }
    
    var isLegacy: Bool {
        false
//        date.startOfDay < Date.now.startOfDay
    }
    
    var calculatedWeightInKg: Double? {
        switch dailyValueType {
        case .average:
            measurements.compactMap { $0.weightInKg }.average
        case .last:
            measurements.last?.weightInKg
        case .first:
            measurements.first?.weightInKg
        }
    }

    var weight: HealthDetails.Weight {
        HealthDetails.Weight(
            weightInKg: calculatedWeightInKg,
            dailyValueType: dailyValueType,
            measurements: measurements,
            deletedHealthKitMeasurements: deletedHealthKitMeasurements
        )
    }
}

#Preview("Current (kg)") {
    NavigationView {
        WeightForm(healthProvider: MockCurrentProvider)
    }
}

#Preview("Past (kg)") {
    NavigationView {
        WeightForm(healthProvider: MockPastProvider)
    }
}

#Preview("Current (st)") {
    NavigationView {
        WeightForm(healthProvider: MockCurrentProvider)
    }
}

#Preview("Past (st)") {
    NavigationView {
        WeightForm(healthProvider: MockPastProvider)
    }
}

#Preview("Current (lb)") {
    NavigationView {
        WeightForm(healthProvider: MockCurrentProvider)
    }
}

#Preview("Past (lb)") {
    NavigationView {
        WeightForm(healthProvider: MockPastProvider)
    }
}

#Preview("Demo") {
    DemoView()
}
