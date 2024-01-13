import SwiftUI
import SwiftSugar
import PrepShared

struct HeightForm: View {

    @Bindable var healthProvider: HealthProvider
    
    let date: Date
    let initialHeight: HealthDetails.Height

    @State var heightInCm: Double?
    @State var measurements: [HeightMeasurement]
    @State var deletedHealthKitMeasurements: [HeightMeasurement]
    @State var isSynced: Bool

    @State var showingForm = false

    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool
    
    let saveHandler: (HealthDetails.Height) -> ()

    init(
        date: Date,
        height: HealthDetails.Height,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false),
        save: @escaping (HealthDetails.Height) -> ()
    ) {
        self.date = date
        self.initialHeight = height
        self.saveHandler = save
        self.healthProvider = healthProvider
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: date.isToday)
                
        _heightInCm = State(initialValue: height.heightInCm)
        _measurements = State(initialValue: height.measurements)
        _deletedHealthKitMeasurements = State(initialValue: height.deletedHealthKitMeasurements)
        _isSynced = State(initialValue: healthProvider.settingsProvider.heightIsHealthKitSynced)
    }

    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            height: healthProvider.healthDetails.height,
            healthProvider: healthProvider,
            isPresented: isPresented,
            dismissDisabled: dismissDisabled,
            save: healthProvider.saveHeight(_:)
        )
    }
    
    var body: some View {
        Form {
            noticeOrDateSection
            measurementsSections
            dailyValueInfoSection
            syncSection
            explanation
        }
        .navigationTitle("Height")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingForm) { measurementForm }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isLegacy && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
        .onChange(of: isSynced, isSyncedChanged)
    }
    
    var dailyValueInfoSection: some View {
        var description: String {
            DailyValueType.last.description
        }

        var header: some View {
            Text("Handling Multiple Measurements")
        }

        return Section(header: header) {
            Text(description)
        }
    }
    
    func isSyncedChanged(old: Bool, new: Bool) {
        healthProvider.setHealthKitSyncing(for: .height, to: new)
    }
    
    var heightUnit: HeightUnit {
        healthProvider.settingsProvider.heightUnit
    }
    
    var bottomValue: some View {
        
        var double: Double? {
            guard let heightInCm else { return nil }
            return HeightUnit.cm
                .doubleComponent(heightInCm, in: heightUnit)
        }
        
        var int: Int? {
            guard let heightInCm else { return nil }
            return HeightUnit.cm
                .intComponent(heightInCm, in: heightUnit)
        }
        
        var intUnitString: String? { heightUnit.intUnitString }
        var doubleUnitString: String { heightUnit.doubleUnitString }
        
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
    
    var measurementForm: some View {
        MeasurementForm(type: .height, date: date) { int, double, time in
            let heightInCm = heightUnit.convert(int, double, to: .cm)
            let measurement = HeightMeasurement(date: time, heightInCm: heightInCm)
            measurements.append(measurement)
            measurements.sort()
            handleChanges()
        }
    }
    
    @ViewBuilder
    var syncSection: some View {
        if !isLegacy {
            SyncSection(
                healthDetail: .height,
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
    
    var explanation: some View {
        var header: some View {
            Text("Usage")
                .formTitleStyle()
        }

        return Section(header: header) {
            VStack(alignment: .leading) {
                Text("Your height is used in certain equations when calculating your:")
                dotPoint("Resting Energy")
                dotPoint("Lean Body Mass")
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
    
    var measurementsSections: some View {
        MeasurementsSections<HeightUnit>(
            measurements: Binding<[any Measurable]>(
                get: { measurements },
                set: { newValue in
                    guard let measurements = newValue as? [HeightMeasurement] else { return }
                    self.measurements = measurements
                }
            ),
            deletedHealthKitMeasurements: Binding<[any Measurable]>(
                get: { deletedHealthKitMeasurements },
                set: { newValue in
                    guard let measurements = newValue as? [HeightMeasurement] else { return }
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
//            dailyValueType: .constant(.last),
            handleChanges: handleChanges
        )
    }
    
    //MARK: - Actions
    
    func save() {
        saveHandler(height)
    }
    
    func undo() {
        self.heightInCm = initialHeight.heightInCm
        self.measurements = initialHeight.measurements
        self.deletedHealthKitMeasurements = initialHeight.deletedHealthKitMeasurements
    }

    func setDismissDisabled() {
        dismissDisabled = isLegacy && isEditing && isDirty
    }

    func handleChanges() {
        heightInCm = lastMeasurementInCm
        setIsDirty()
        if !isLegacy {
            save()
        }
    }

    func setIsDirty() {
        isDirty = height != initialHeight
    }

    //MARK: - Convenience

    var lastMeasurementInCm: Double? {
        measurements.last?.heightInCm
    }
    
    var height: HealthDetails.Height {
        HealthDetails.Height(
            heightInCm: lastMeasurementInCm,
            measurements: measurements,
            deletedHealthKitMeasurements: deletedHealthKitMeasurements
        )
    }

    var isDisabled: Bool {
        isLegacy && !isEditing
    }
    
    var controlColor: Color {
        isDisabled ? .secondary : .primary
    }
    
    var isLegacy: Bool {
        date.startOfDay < Date.now.startOfDay
    }
}

//#Preview("Current (ft)") {
//    NavigationView {
//        HeightForm(healthProvider: MockCurrentProvider)
//            .environment(SettingsProvider(settings: .init(heightUnit: .ft)))
//    }
//}
//
//#Preview("Past (ft)") {
//    NavigationView {
//        HeightForm(healthProvider: MockPastProvider)
//            .environment(SettingsProvider(settings: .init(heightUnit: .ft)))
//    }
//}
//
//#Preview("Current (cm)") {
//    NavigationView {
//        HeightForm(healthProvider: MockCurrentProvider)
//            .environment(SettingsProvider(settings: .init(heightUnit: .cm)))
//    }
//}
//
//#Preview("Past (cm)") {
//    NavigationView {
//        HeightForm(healthProvider: MockPastProvider)
//            .environment(SettingsProvider(settings: .init(heightUnit: .cm)))
//    }
//}
//
//#Preview("Current (m)") {
//    NavigationView {
//        HeightForm(healthProvider: MockCurrentProvider)
//            .environment(SettingsProvider(settings: .init(heightUnit: .m)))
//    }
//}
//
//#Preview("Past (m)") {
//    NavigationView {
//        HeightForm(healthProvider: MockPastProvider)
//            .environment(SettingsProvider(settings: .init(heightUnit: .m)))
//    }
//}
