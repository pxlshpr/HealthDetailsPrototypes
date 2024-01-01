import SwiftUI
import SwiftSugar
import PrepShared

struct WeightForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    
    let date: Date
    let initialWeight: HealthDetails.Weight
    
//    @Bindable var healthProvider: HealthProvider
//    let initialMeasurements: [WeightMeasurement]
//    let initialDeletedHealthKitMeasurements: [WeightMeasurement]
//    let initialDailyValueType: DailyValueType

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
//        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false),
        save: @escaping (HealthDetails.Weight) -> ()
    ) {
        self.date = date
        self.initialWeight = weight
        self.saveHandler = save
//        self.healthProvider = healthProvider
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
//        _isEditing = State(initialValue: healthProvider.isCurrent)
        _isEditing = State(initialValue: date.isToday)

//        let weight = healthProvider.healthDetails.weight
        _weightInKg = State(initialValue: weight.weightInKg)
        _measurements = State(initialValue: weight.measurements)
        _dailyValueType = State(initialValue: weight.dailyValueType)
        _deletedHealthKitMeasurements = State(initialValue: weight.deletedHealthKitMeasurements)
        _isSynced = State(initialValue: weight.isSynced)

//        self.initialMeasurements = weight.measurements
//        self.initialDeletedHealthKitMeasurements = weight.deletedHealthKitMeasurements
//        self.initialDailyValueType = weight.dailyValueType
    }
    
    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            weight: healthProvider.healthDetails.weight,
            isPresented: isPresented,
            dismissDisabled: dismissDisabled,
            save: healthProvider.saveWeight(_:)
        )
    }
    var body: some View {
        Form {
            noticeOrDateSection
            measurementsSections
            syncSection
            explanation
        }
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingForm) { measurementForm }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isPast && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    var explanation: some View {
        var header: some View {
            Text("Usage")
                .formTitleStyle()
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
                get: { isPast },
                set: { _ in }
            ),
            isEditing: Binding<Bool>(
                get: { isEditing },
                set: { _ in }
            ),
            dailyValueType: $dailyValueType,
            handleChanges: handleChanges
        )
    }
    
    var measurementForm: some View {
        MeasurementForm(
            type: .weight,
//            date: pastDate
            date: date
        ) { int, double, time in
            let weightInKg = settingsProvider.bodyMassUnit.convert(int, double, to: .kg)
            let measurement = WeightMeasurement(date: time, weightInKg: weightInKg)
            measurements.append(measurement)
            measurements.sort()
            handleChanges()
        }
    }


    var bottomValue: some View {
        
        var bottomRow: some View {
            
            var intUnitString: String? {
                settingsProvider.bodyMassUnit.intUnitString
            }
            
            var doubleUnitString: String {
                settingsProvider.bodyMassUnit.doubleUnitString
            }
            
            var double: Double? {
                guard let weightInKg else { return nil }
                return BodyMassUnit.kg
                    .doubleComponent(weightInKg, in: settingsProvider.bodyMassUnit)
            }
            
            var int: Int? {
                guard let weightInKg else { return nil }
                return BodyMassUnit.kg
                    .intComponent(weightInKg, in: settingsProvider.bodyMassUnit)
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
                ),
                isStyledAsBottomBar: false
            )
        }

        var topRow: some View {
            dailyValuePicker
        }
        
        return VStack {
            topRow
            bottomRow
        }
        .padding(.horizontal, BottomValueHorizontalPadding)
        .padding(.vertical, BottomValueVerticalPadding)
        .background(.bar)
    }
    
    @ViewBuilder
    var noticeOrDateSection: some View {
//        if let pastDate {
//            NoticeSection.legacy(pastDate, isEditing: $isEditing)
        if isPast {
            NoticeSection.legacy(date, isEditing: $isEditing)
        } else {
            Section {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(Date.now.shortDateString)
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
        
        return Picker("", selection: binding) {
            ForEach(DailyValueType.allCases, id: \.self) {
                Text($0.name).tag($0)
            }
        }
        .pickerStyle(.segmented)
        .listRowSeparator(.hidden)
        .disabled(isDisabled || measurements.isEmpty)
    }

    @ViewBuilder
    var syncSection: some View {
        if !isPast {
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
            isPast: isPast,
            dismissAction: { isPresented = false },
            undoAction: undo,
            saveAction: save
        )
    }
    
    //MARK: - Actions
    
    func setIsDirty() {
        isDirty = weight != initialWeight
//        isDirty = measurements != initialMeasurements
//        || deletedHealthKitMeasurements != initialDeletedHealthKitMeasurements
//        || dailyValueType != initialDailyValueType
    }
    
    func setDismissDisabled() {
        dismissDisabled = isPast && isEditing && isDirty
    }

    func handleChanges() {
        weightInKg = calculatedWeightInKg
        setIsDirty()
        if !isPast {
            save()
        }
    }

    func undo() {
//        let weight = healthProvider.healthDetails.weight
        self.weightInKg = weight.weightInKg
        self.dailyValueType = weight.dailyValueType
        self.measurements = weight.measurements
        self.deletedHealthKitMeasurements = weight.deletedHealthKitMeasurements
        self.isSynced = weight.isSynced
    }
    
    func save() {
        saveHandler(weight)
//        healthProvider.saveWeight(weight)
    }

    //MARK: - Convenience
    
    var isDisabled: Bool {
        isPast && !isEditing
    }
    
    var controlColor: Color {
        isDisabled ? .secondary : .primary
    }
    
    var isPast: Bool {
        date.startOfDay < Date.now.startOfDay
//        pastDate != nil
    }
    
//    var pastDate: Date? {
//        healthProvider.pastDate
//    }

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
            deletedHealthKitMeasurements: deletedHealthKitMeasurements,
            isSynced: isSynced
        )
    }
}

#Preview("Current (kg)") {
    NavigationView {
        WeightForm(healthProvider: MockCurrentProvider)
            .environment(SettingsProvider(settings: .init(bodyMassUnit: .kg)))
    }
}

#Preview("Past (kg)") {
    NavigationView {
        WeightForm(healthProvider: MockPastProvider)
            .environment(SettingsProvider(settings: .init(bodyMassUnit: .kg)))
    }
}

#Preview("Current (st)") {
    NavigationView {
        WeightForm(healthProvider: MockCurrentProvider)
            .environment(SettingsProvider(settings: .init(bodyMassUnit: .st)))
    }
}

#Preview("Past (st)") {
    NavigationView {
        WeightForm(healthProvider: MockPastProvider)
            .environment(SettingsProvider(settings: .init(bodyMassUnit: .st)))
    }
}

#Preview("Current (lb)") {
    NavigationView {
        WeightForm(healthProvider: MockCurrentProvider)
            .environment(SettingsProvider(settings: .init(bodyMassUnit: .lb)))
    }
}

#Preview("Past (lb)") {
    NavigationView {
        WeightForm(healthProvider: MockPastProvider)
            .environment(SettingsProvider(settings: .init(bodyMassUnit: .lb)))
    }
}

#Preview("Demo") {
    DemoView()
}
