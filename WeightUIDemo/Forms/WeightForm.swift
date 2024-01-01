import SwiftUI
import SwiftSugar
import PrepShared

struct WeightForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    @Bindable var healthProvider: HealthProvider

    @State var weightInKg: Double?
    @State var dailyValueType: DailyValueType
    @State var measurements: [WeightMeasurement]
    @State var deletedHealthKitMeasurements: [WeightMeasurement]
    @State var isSynced: Bool = true

    let initialMeasurements: [WeightMeasurement]
    let initialDeletedHealthKitMeasurements: [WeightMeasurement]
    let initialDailyValueType: DailyValueType

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
        
        let weight = healthProvider.healthDetails.weight
        _weightInKg = State(initialValue: weight.weightInKg)
        _measurements = State(initialValue: weight.measurements)
        _dailyValueType = State(initialValue: weight.dailyValueType)
        _deletedHealthKitMeasurements = State(initialValue: weight.deletedHealthKitMeasurements)
        _isSynced = State(initialValue: weight.isSynced)

        self.initialMeasurements = weight.measurements
        self.initialDeletedHealthKitMeasurements = weight.deletedHealthKitMeasurements
        self.initialDailyValueType = weight.dailyValueType
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
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .confirmationDialog("Turn Off Sync", isPresented: $showingSyncOffConfirmation, titleVisibility: .visible) {
            Button("Turn Off", role: .destructive) {
                isSynced = false
                handleChanges()
            }
        } message: {
            Text("Weight data will no longer be read from or written to Apple Health.")
        }
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

    var intUnitString: String? {
        settingsProvider.bodyMassUnit.intUnitString
    }
    
    var doubleUnitString: String {
        settingsProvider.bodyMassUnit.doubleUnitString
    }

    func cell(for measurement: WeightMeasurement, disabled: Bool = false) -> some View {
        
        var double: Double {
            BodyMassUnit.kg
                .doubleComponent(measurement.weightInKg, in: settingsProvider.bodyMassUnit)
        }
        
        var int: Int? {
            BodyMassUnit.kg
                .intComponent(measurement.weightInKg, in: settingsProvider.bodyMassUnit)
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
    
//    func cell_(for data: WeightMeasurement, disabled: Bool = false) -> some View {
//        @ViewBuilder
//        var image: some View {
//            switch data.isFromHealthKit {
//            case true:
//                Image("AppleHealthIcon")
//                    .resizable()
//                    .frame(width: 24, height: 24)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 5)
//                            .stroke(Color(.systemGray3), lineWidth: 0.5)
//                    )
//            case false:
//                Image(systemName: "pencil")
//                    .frame(width: 24, height: 24)
//                    .background(
//                        RoundedRectangle(cornerRadius: 5)
//                            .foregroundStyle(Color(.systemGray4))
//                    )
//            }
//        }
//        
//        @ViewBuilder
//        var deleteButton: some View {
//            if isEditing, isPast {
//                Button {
//                    withAnimation {
//                        delete(data)
//                    }
//                } label: {
//                    Image(systemName: "minus.circle.fill")
//                        .imageScale(.large)
//                        .foregroundStyle(.red)
//                }
//                .buttonStyle(.plain)
//            }
//        }
//        
//        return HStack {
//            deleteButton
//                .opacity(disabled ? 0.6 : 1)
//            image
//            Text(data.dateString)
//                .foregroundStyle(disabled ? .secondary : .primary)
//            Spacer()
//            Text(data.valueString(unit: "kg"))
//                .foregroundStyle(disabled ? .secondary : .primary)
//        }
//    }
    
    var list: some View {
        @ViewBuilder
        var footer: some View {
            if !measurements.isEmpty {
                Text(DailyValueType.last.description)
            }
        }
        
        var lastRow: some View {
            var shouldShow: Bool {
                !(isDisabled && !measurements.isEmpty)
            }
            
            var content: some View {
                HStack {
                    if isDisabled {
                        if measurements.isEmpty {
                            Text("No Measurements")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Add Measurement")
                            .foregroundStyle(Color.accentColor)
                    }
                    Spacer()
                    Button {
                        showingForm = true
                    } label: {
                    }
                    .disabled(isDisabled)
                }
            }
            
            return Group {
                if shouldShow {
                    content
                }
            }
        }
        
        var cells: some View {
            ForEach(measurements) { data in
                cell(for: data)
                    .deleteDisabled(isPast)
            }
            .onDelete(perform: delete)
        }
        
        return Section(footer: footer) {
            cells
            lastRow
        }
    }
    
    var measurementForm: some View {
        MeasurementForm(type: .weight, date: pastDate) { int, double, time in
            let weightInKg = settingsProvider.bodyMassUnit.convert(int, double, to: .kg)
            let measurement = WeightMeasurement(date: time, weightInKg: weightInKg)
            addMeasurement(measurement)
            handleChanges()
        }
    }

    func addMeasurement(_ measurement: WeightMeasurement) {
        measurements.append(measurement)
        measurements.sort()
    }

    var bottomValue: some View {
        
        var bottomRow: some View {
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
                ),
                isStyledAsBottomBar: false
            )
        }
        
//        var bottomRow: some View {
//            HStack(alignment: .firstTextBaseline, spacing: 5) {
//                Spacer()
//                if let weightInKg {
//                    Text("\(weightInKg.roundedToOnePlace)")
//                        .contentTransition(.numericText(value: weightInKg))
//                        .font(LargeNumberFont)
//                        .foregroundStyle(isDisabled ? .secondary : .primary)
//                    Text("kg")
//                        .font(LargeUnitFont)
//                        .foregroundStyle(isDisabled ? .tertiary : .secondary)
//                } else {
//                    ZStack {
//
//                        /// dummy text placed to ensure height stays consistent
//                        Text("0")
//                            .font(LargeNumberFont)
//                            .opacity(0)
//                        
//                        Text("Not Set")
//                            .font(LargeUnitFont)
//                            .foregroundStyle(isDisabled ? .tertiary : .secondary)
//                    }
//                }
//            }
//        }
        
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
    
    var deletedList: some View {
        var header: some View {
            Text("Ignored Apple Health Data")
        }
        
        func restore(_ measurement: WeightMeasurement) {
            withAnimation {
                addMeasurement(measurement)
                deletedHealthKitMeasurements.removeAll(where: { $0.id == measurement.id })
                handleChanges()
            }
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
        .disabled(isDisabled)
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
            Section(footer: Text("Automatically imports your Weight data from Apple Health. Data you add here will also be exported back to Apple Health.")) {
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
    
    //MARK: - Actions
    
    func setIsDirty() {
        isDirty = measurements != initialMeasurements
        || deletedHealthKitMeasurements != initialDeletedHealthKitMeasurements
        || dailyValueType != initialDailyValueType
    }
    
    func setDismissDisabled() {
        dismissDisabled = isPast && isEditing && isDirty
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
            deletedHealthKitMeasurements: deletedHealthKitMeasurements,
            isSynced: isSynced
        )
    }

    func handleChanges() {
        weightInKg = calculatedWeightInKg
        setIsDirty()
        if !isPast {
            save()
        }
    }

    func undo() {
        let weight = healthProvider.healthDetails.weight
        self.weightInKg = weight.weightInKg
        self.dailyValueType = weight.dailyValueType
        self.measurements = weight.measurements
        self.deletedHealthKitMeasurements = weight.deletedHealthKitMeasurements
        self.isSynced = weight.isSynced
    }
    
    func save() {
        healthProvider.saveWeight(weight)
    }

    func delete(_ data: WeightMeasurement) {
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
}

let MockWeightData: [HeightMeasurement] = [
    .init(UUID(uuidString: "F89DC6EC-F6C9-49B0-A860-6BFABE48A2BC")!, Date(fromShortTimeString: "09_42")!, 95.4),
    .init(UUID(uuidString: "B18C3606-7790-48B8-B62B-76C928BEAE3B")!, Date(fromShortTimeString: "12_07")!, 94.4, UUID(uuidString: "5F507BFC-6BCB-4BE6-88B2-3FD4BEFE4556")!),
    .init(UUID(uuidString: "BAFFCD6B-B9D8-46B8-878D-771FB3895D4C")!, Date(fromShortTimeString: "13_23")!, 94.3),
    .init(UUID(uuidString: "EA1716DA-4DD0-4549-9ED6-955FFEEDEB79")!, Date(fromShortTimeString: "15_01")!, 94.7, UUID(uuidString: "9B12AB6D-69DA-4FAC-9D80-3D0BB6A67D50")!),
    .init(UUID(uuidString: "49CB4FF0-673C-4FCC-BF66-0E04E06C4A72")!, Date(fromShortTimeString: "17_35")!, 95.1),
    .init(UUID(uuidString: "E45059D5-6AF6-49F7-91FB-BFABF9533405")!, Date(fromShortTimeString: "19_54")!, 94.5),
]

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

#Preview("Demo ") {
    DemoView()
}
