import SwiftUI
import SwiftSugar
import PrepShared

struct LeanBodyMassForm: View {
    
    @Bindable var healthProvider: HealthProvider

    let date: Date
    let initialLeanBodyMass: HealthDetails.LeanBodyMass

    @State var leanBodyMassInKg: Double?
    @State var fatPercentage: Double?
    @State var dailyValueType: DailyValueType
    @State var measurements: [LeanBodyMassMeasurement]
    @State var deletedHealthKitMeasurements: [LeanBodyMassMeasurement]
    @State var isSynced: Bool = true
    
    @State var showingForm = false
    
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool
    
    let saveHandler: (HealthDetails.LeanBodyMass) -> ()

    init(
        date: Date,
        leanBodyMass: HealthDetails.LeanBodyMass,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false),
        save: @escaping (HealthDetails.LeanBodyMass) -> ()
    ) {
        self.date = date
        self.initialLeanBodyMass = leanBodyMass
        self.saveHandler = save
        self.healthProvider = healthProvider
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: date.isToday)
        
        _leanBodyMassInKg = State(initialValue: leanBodyMass.leanBodyMassInKg)
        _measurements = State(initialValue: leanBodyMass.measurements)
        _dailyValueType = State(initialValue: healthProvider.settingsProvider.settings.dailyValueType(for: .leanBodyMass))
        _deletedHealthKitMeasurements = State(initialValue: leanBodyMass.deletedHealthKitMeasurements)
        _isSynced = State(initialValue: healthProvider.settingsProvider.leanBodyMassIsHealthKitSynced)
    }
    
    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            leanBodyMass: healthProvider.healthDetails.leanBodyMass,
            healthProvider: healthProvider,
            isPresented: isPresented,
            dismissDisabled: dismissDisabled,
            save: healthProvider.saveLeanBodyMass
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
        .navigationTitle("Lean Body Mass")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingForm) { measurementForm }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isLegacy && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
        .onChange(of: isSynced, isSyncedChanged)
    }
    
    func isSyncedChanged(old: Bool, new: Bool) {
        healthProvider.setHealthKitSyncing(for: .leanBodyMass, to: new)
    }

    //MARK: - Sections
    
    var explanation: some View {
        var header: some View {
            Text("Usage")
                .formTitleStyle()
        }
        
        return Section(header: header) {
            VStack(alignment: .leading) {
                Text("Your lean body mass is the weight of your body minus your body fat (adipose tissue). It is used when:")
                dotPoint("Creating goals. For example, you could create a protein goal relative to your lean body mass instead of your weight.")
                dotPoint("Calculating your Resting Energy using certain equations.")
            }
        }
    }
    
    
    @ViewBuilder
    var noticeOrDateSection: some View {
        if isLegacy {
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
    
    var bodyMassUnit: BodyMassUnit {
        healthProvider.settingsProvider.bodyMassUnit
    }
    
    var bottomValue: some View {
        var intUnitString: String? { bodyMassUnit.intUnitString }
        var doubleUnitString: String { bodyMassUnit.doubleUnitString }
        
        var double: Double? {
            guard let leanBodyMassInKg else { return nil }
            return BodyMassUnit.kg
                .doubleComponent(leanBodyMassInKg, in: bodyMassUnit)
        }
        
        var int: Int? {
            guard let leanBodyMassInKg else { return nil }
            return BodyMassUnit.kg
                .intComponent(leanBodyMassInKg, in: bodyMassUnit)
        }
        
        return HStack(alignment: .firstTextBaseline, spacing: 5) {
            if let fatPercentage {
                Text("\(fatPercentage.roundedToOnePlace)")
                    .contentTransition(.numericText(value: fatPercentage))
                    .font(LargeNumberFont)
                    .foregroundStyle(isDisabled ? .secondary : .primary)
                Text("% fat")
                    .font(LargeUnitFont)
                    .foregroundStyle(isDisabled ? .tertiary : .secondary)
            }
            Spacer()
            MeasurementBottomText(
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
    
    //MARK: - Rewrite
    var measurementForm: some View {
        LeanBodyMassMeasurementForm(healthProvider: healthProvider) { measurement in
            measurements.append(measurement)
            measurements.sort()
            handleChanges()
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
            dailyValueType.description(for: .leanBodyMass)
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
                healthDetail: .leanBodyMass,
                isSynced: $isSynced,
                handleChanges: handleChanges
            )
        }
    }
    
    var measurementsSections: some View {
        MeasurementsSections<BodyMassUnit>(
            measurements: Binding<[any Measurable]>(
                get: { measurements },
                set: { newValue in
                    guard let measurements = newValue as? [LeanBodyMassMeasurement] else { return }
                    self.measurements = measurements
                }
            ),
            deletedHealthKitMeasurements: Binding<[any Measurable]>(
                get: { deletedHealthKitMeasurements },
                set: { newValue in
                    guard let measurements = newValue as? [LeanBodyMassMeasurement] else { return }
                    self.deletedHealthKitMeasurements = measurements
                }
            ),
            showingForm: $showingForm,
            handleChanges: handleChanges
        )
    }
    
    //MARK: - Actions
    
    func setDismissDisabled() {
        dismissDisabled = isLegacy && isEditing && isDirty
    }
    
    
    func undo() {
        self.leanBodyMassInKg = initialLeanBodyMass.leanBodyMassInKg
        self.measurements = initialLeanBodyMass.measurements
        self.deletedHealthKitMeasurements = initialLeanBodyMass.deletedHealthKitMeasurements
    }
    
    func save() {
        saveHandler(leanBodyMass)
    }
    
    func setIsDirty() {
        isDirty = leanBodyMass != initialLeanBodyMass
    }
    
    func handleChanges() {
        leanBodyMassInKg = calculatedLeanBodyMassInKg
        setIsDirty()
        if !isLegacy {
            save()
        }
    }
    
    //MARK: - Convenience
    
    var isDisabled: Bool {
        isLegacy && !isEditing
    }
    
    var controlColor: Color {
        isDisabled ? .secondary : .primary
    }
    
    var isLegacy: Bool {
        date.startOfDay < Date.now.startOfDay
    }
    
    var calculatedLeanBodyMassInKg: Double? {
        switch dailyValueType {
        case .average:
            measurements.compactMap { $0.leanBodyMassInKg }.average
        case .last:
            measurements.last?.leanBodyMassInKg
        case .first:
            measurements.first?.leanBodyMassInKg
        }
    }
    
    var calculatedFatPercentage: Double? {
        switch dailyValueType {
        case .average:
            measurements.compactMap { $0.fatPercentage }.average
        case .last:
            measurements.last?.fatPercentage
        case .first:
            measurements.first?.fatPercentage
        }
    }
    
    var leanBodyMass: HealthDetails.LeanBodyMass {
        HealthDetails.LeanBodyMass(
            leanBodyMassInKg: calculatedLeanBodyMassInKg,
            fatPercentage: calculatedFatPercentage,
            measurements: measurements,
            deletedHealthKitMeasurements: deletedHealthKitMeasurements
        )
    }
}

#Preview("Current (kg)") {
    NavigationView {
        LeanBodyMassForm(healthProvider: MockCurrentProvider)
            .environment(SettingsProvider(settings: .init(bodyMassUnit: .kg)))
    }
}

#Preview("Past (kg)") {
    NavigationView {
        LeanBodyMassForm(healthProvider: MockPastProvider)
            .environment(SettingsProvider(settings: .init(bodyMassUnit: .kg)))
    }
}

#Preview("Current (st)") {
    NavigationView {
        LeanBodyMassForm(healthProvider: MockCurrentProvider)
            .environment(SettingsProvider(settings: .init(bodyMassUnit: .st)))
    }
}

#Preview("Past (st)") {
    NavigationView {
        LeanBodyMassForm(healthProvider: MockPastProvider)
            .environment(SettingsProvider(settings: .init(bodyMassUnit: .st)))
    }
}

#Preview("Current (lb)") {
    NavigationView {
        LeanBodyMassForm(healthProvider: MockCurrentProvider)
            .environment(SettingsProvider(settings: .init(bodyMassUnit: .lb)))
    }
}

#Preview("Past (lb)") {
    NavigationView {
        LeanBodyMassForm(healthProvider: MockPastProvider)
            .environment(SettingsProvider(settings: .init(bodyMassUnit: .lb)))
    }
}

#Preview("Demo") {
    DemoView()
}
