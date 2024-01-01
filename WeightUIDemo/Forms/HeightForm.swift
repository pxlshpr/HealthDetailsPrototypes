import SwiftUI
import SwiftSugar
import PrepShared

struct HeightForm: View {

    @Environment(SettingsProvider.self) var settingsProvider
    @Bindable var healthProvider: HealthProvider
    
    @State var heightInCm: Double?
    @State var measurements: [HeightMeasurement]
    @State var deletedHealthKitMeasurements: [HeightMeasurement]
    @State var isSynced: Bool

    let initialMeasurements: [HeightMeasurement]
    let initialDeletedHealthKitMeasurements: [HeightMeasurement]
    
    @State var showingForm = false
    @State var showingSyncOffConfirmation: Bool = false
    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24

    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool
    
    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.healthProvider = healthProvider
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: healthProvider.isCurrent)
                
        let height = healthProvider.healthDetails.height
        _heightInCm = State(initialValue: height.heightInCm)
        _measurements = State(initialValue: height.measurements)
        _deletedHealthKitMeasurements = State(initialValue: height.deletedHealthKitMeasurements)
        _isSynced = State(initialValue: height.isSynced)

        self.initialMeasurements = height.measurements
        self.initialDeletedHealthKitMeasurements = height.deletedHealthKitMeasurements
    }

    var pastDate: Date? {
        healthProvider.pastDate
    }

    var body: some View {
        Form {
            noticeOrDateSection
            list
            deletedList
            syncSection
            explanation
        }
        .navigationTitle("Height")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .confirmationDialog("Turn Off Sync", isPresented: $showingSyncOffConfirmation, titleVisibility: .visible) {
            Button("Turn Off", role: .destructive) {
                isSynced = false
                handleChanges()
            }
        } message: {
            Text("Height data will no longer be read from or written to Apple Health.")
        }
        .sheet(isPresented: $showingForm) { measurementForm }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isPast && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    var intUnitString: String? {
        settingsProvider.heightUnit.intUnitString
    }
    
    var doubleUnitString: String {
        settingsProvider.heightUnit.doubleUnitString
    }
    
    var bottomValue: some View {
        
        var double: Double? {
            guard let heightInCm else { return nil }
            return HeightUnit.cm
                .doubleComponent(heightInCm, in: settingsProvider.heightUnit)
        }
        
        var int: Int? {
            guard let heightInCm else { return nil }
            return HeightUnit.cm
                .intComponent(heightInCm, in: settingsProvider.heightUnit)
        }
        
        return BottomValue(
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
        MeasurementForm(type: .height, date: pastDate) { int, double, time in
            let heightInCm = settingsProvider.heightUnit.convert(int, double, to: .cm)
            let measurement = HeightMeasurement(date: time, heightInCm: heightInCm)
            addMeasurement(measurement)
            handleChanges()
        }
    }
    
    func addMeasurement(_ measurement: HeightMeasurement) {
        measurements.append(measurement)
        measurements.sort()
    }
    
    var deletedList: some View {
        var header: some View {
            Text("Ignored Apple Health Data")
        }
        
        func restore(_ measurement: HeightMeasurement) {
            withAnimation {
                addMeasurement(measurement)
                deletedHealthKitMeasurements.removeAll(where: { $0.id == measurement.id })
            }
            handleChanges()
        }
        
        return Group {
            if !deletedHealthKitMeasurements.isEmpty {
                Section(header: header) {
                    ForEach(deletedHealthKitMeasurements) { data in
                        HStack {
                            cell(for: data, disabled: true)
                            Button {
                                restore(data)
                            } label: {
                                Image(systemName: "arrow.up.bin")
                            }
                        }
                    }
                }
            }
        }
    }
    
    var syncSection: some View {
        let binding = Binding<Bool>(
            get: { isSynced },
            set: { newValue in
                if !newValue {
                    showingSyncOffConfirmation = true
                } else {
                    isSynced = newValue
                    handleChanges()
                }
            }
        )
        
        var section: some View {
            Section(footer: Text("Automatically reads height data from Apple Health. Data you enter here will also be exported back to Apple Health.")) {
                HStack {
                    Image("AppleHealthIcon")
                        .resizable()
                        .frame(width: imageScale * scale, height: imageScale * scale)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color(.systemGray3), lineWidth: 0.5)
                        )
                    Text("Sync with Apple Health")
                        .layoutPriority(1)
                    Spacer()
                    Toggle("", isOn: binding)
                }
            }
        }
        
        return Group {
            if !isPast {
                section
            }
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
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: $isEditing)
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
    
    func cell(for measurement: HeightMeasurement, disabled: Bool = false) -> some View {
        var double: Double {
            HeightUnit.cm
                .doubleComponent(measurement.heightInCm, in: settingsProvider.heightUnit)
        }

        var int: Int? {
            HeightUnit.cm
                .intComponent(measurement.heightInCm, in: settingsProvider.heightUnit)
        }
        
        return MeasurementCell(
            imageType: measurement.imageType,
            timeString: measurement.timeString,
            isDisabled: disabled,
            showDeleteButton: Binding<Bool>(
                get: { isEditing && isPast },
                set: { _ in }
            ),
            deleteAction: {
                withAnimation {
                    delete(measurement)
                }
            },
            double: double,
            int: int,
            doubleUnitString: doubleUnitString,
            intUnitString: intUnitString
        )
    }
    
    var list: some View {
        MeasurementsSection<HeightUnit>(
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
                get: { isPast },
                set: { _ in }
            ),
            isEditing: Binding<Bool>(
                get: { isEditing },
                set: { _ in }
            ),
            handleChanges: handleChanges
        )
    }
    
//    var list_: some View {
//        @ViewBuilder
//        var footer: some View {
//            if !measurements.isEmpty {
//                Text(DailyValueType.last.description)
//            }
//        }
//        
//        var lastRow: some View {
//            var shouldShow: Bool {
//                !(isDisabled && !measurements.isEmpty)
//            }
//            
//            var content: some View {
//                HStack {
//                    if isDisabled {
//                        if measurements.isEmpty {
//                            Text("No Measurements")
//                                .foregroundStyle(.secondary)
//                        }
//                    } else {
//                        Text("Add Measurement")
//                            .foregroundStyle(Color.accentColor)
//                    }
//                    Spacer()
//                    Button {
//                        showingForm = true
//                    } label: {
//                    }
//                    .disabled(isDisabled)
//                }
//            }
//            
//            return Group {
//                if shouldShow {
//                    content
//                }
//            }
//        }
//        
//        var cells: some View {
//            ForEach(measurements) { data in
//                cell(for: data)
//                    .deleteDisabled(isPast)
//            }
//            .onDelete(perform: delete)
//        }
//        
//        return Section(footer: footer) {
//            cells
//            lastRow
//        }
//    }
    
    //MARK: - Actions
    
    func save() {
        healthProvider.saveHeight(height)
    }
    
    func undo() {
        let height = healthProvider.healthDetails.height
        self.heightInCm = height.heightInCm
        self.measurements = height.measurements
        self.deletedHealthKitMeasurements = height.deletedHealthKitMeasurements
        self.isSynced = height.isSynced
    }

    var lastMeasurementInCm: Double? {
        measurements.last?.heightInCm
    }
    
    var height: HealthDetails.Height {
        HealthDetails.Height(
            heightInCm: lastMeasurementInCm,
            measurements: measurements,
            deletedHealthKitMeasurements: deletedHealthKitMeasurements,
            isSynced: isSynced
        )
    }

    func delete(_ data: HeightMeasurement) {
        if data.isFromHealthKit {
            deletedHealthKitMeasurements.append(data)
            deletedHealthKitMeasurements.sort()
        }
        measurements.removeAll(where: { $0.id == data.id })
        handleChanges()
    }
    
    func delete(at offsets: IndexSet) {
        let dataToDelete = offsets.map { self.measurements[$0] }
        withAnimation {
            for data in dataToDelete {
                delete(data)
            }
        }
    }
    func setDismissDisabled() {
        dismissDisabled = isPast && isEditing && isDirty
    }

    func handleChanges() {
        heightInCm = lastMeasurementInCm
        setIsDirty()
        if !isPast {
            save()
        }
    }

    func setIsDirty() {
        isDirty = measurements != initialMeasurements
        || deletedHealthKitMeasurements != initialDeletedHealthKitMeasurements
    }

    //MARK: - Convenience

    var isDisabled: Bool {
        isPast && !isEditing
    }
    
    var controlColor: Color {
        isDisabled ? .secondary : .primary
    }
    
    var isPast: Bool {
        pastDate != nil
    }
}

#Preview("Current (ft)") {
    NavigationView {
        HeightForm(healthProvider: MockCurrentProvider)
            .environment(SettingsProvider(settings: .init(heightUnit: .ft)))
    }
}

#Preview("Past (ft)") {
    NavigationView {
        HeightForm(healthProvider: MockPastProvider)
            .environment(SettingsProvider(settings: .init(heightUnit: .ft)))
    }
}

#Preview("Current (cm)") {
    NavigationView {
        HeightForm(healthProvider: MockCurrentProvider)
            .environment(SettingsProvider(settings: .init(heightUnit: .cm)))
    }
}

#Preview("Past (cm)") {
    NavigationView {
        HeightForm(healthProvider: MockPastProvider)
            .environment(SettingsProvider(settings: .init(heightUnit: .cm)))
    }
}

#Preview("Current (m)") {
    NavigationView {
        HeightForm(healthProvider: MockCurrentProvider)
            .environment(SettingsProvider(settings: .init(heightUnit: .m)))
    }
}

#Preview("Past (m)") {
    NavigationView {
        HeightForm(healthProvider: MockPastProvider)
            .environment(SettingsProvider(settings: .init(heightUnit: .m)))
    }
}
