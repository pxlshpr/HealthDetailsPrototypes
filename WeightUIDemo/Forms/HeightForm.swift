import SwiftUI
import SwiftSugar

struct HeightForm: View {

    @Environment(SettingsProvider.self) var settingsProvider

    @Bindable var healthProvider: HealthProvider
    
    @State var heightInCm: Double? = nil
    @State var measurements: [HeightMeasurement] = []
    @State var deletedHealthKitMeasurements: [HeightMeasurement] = []
    @State var isSynced: Bool = false

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
                
        if let height = healthProvider.healthDetails.height {
            _heightInCm = State(initialValue: height.heightInCm)
            _measurements = State(initialValue: height.measurements)
            _deletedHealthKitMeasurements = State(initialValue: height.deletedHealthKitMeasurements)
            _isSynced = State(initialValue: height.isSynced)
        }
    }

    var pastDate: Date? {
        healthProvider.pastDate
    }

    var body: some View {
        Form {
            noticeOrDateSection
            list
            deletedList
            syncToggle
            explanation
        }
        .navigationTitle("Height")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .confirmationDialog("Turn Off Sync", isPresented: $showingSyncOffConfirmation, titleVisibility: .visible) {
            Button("Turn Off", role: .destructive) {
                
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
    
    var bottomValue: some View {
        BottomValue(
            value: $heightInCm,
            valueString: Binding<String?>(
                get: { heightInCm?.clean },
                set: { _ in }
            ),
            isDisabled: Binding<Bool>(
                get: { isDisabled },
                set: { _ in }
            ),
            unitString: "cm"
        )
    }
    
    var measurementForm: some View {
        MeasurementForm(type: .height, date: pastDate)
    }
    
    var deletedList: some View {
        var header: some View {
            Text("Ignored Apple Health Data")
        }
        
        func restore(_ data: HeightMeasurement) {
            withAnimation {
                measurements.append(data)
                measurements.sort()
                deletedHealthKitMeasurements.removeAll(where: { $0.id == data.id })
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
    
    var syncToggle: some View {
        let binding = Binding<Bool>(
            get: { isSynced },
            set: {
                if !$0 {
                    showingSyncOffConfirmation = true
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
    
    func cell(for data: HeightMeasurement, disabled: Bool = false) -> some View {
        @ViewBuilder
        var image: some View {
            switch data.isFromHealthKit {
            case true:
                Image("AppleHealthIcon")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(.systemGray3), lineWidth: 0.5)
                    )
            case false:
                Image(systemName: "pencil")
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundStyle(Color(.systemGray4))
                    )
            }
        }
        
        @ViewBuilder
        var deleteButton: some View {
            if isEditing, isPast {
                Button {
                    withAnimation {
                        delete(data)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .imageScale(.large)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        
        return HStack {
            deleteButton
                .opacity(disabled ? 0.6 : 1)
            image
            Text(data.dateString)
                .foregroundStyle(disabled ? .secondary : .primary)
            Spacer()
            Text(data.valueString(unit: "cm"))
                .foregroundStyle(disabled ? .secondary : .primary)
        }
    }
    
    var list: some View {
        @ViewBuilder
        var footer: some View {
            if !measurements.isEmpty {
                Text(DailyValueType.last.description)
            }
        }
        
        var addButton: some View {
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
        
        var cells: some View {
            ForEach(measurements) { data in
                cell(for: data)
                    .deleteDisabled(isPast)
            }
            .onDelete(perform: delete)
        }
        
        return Section(footer: footer) {
            cells
            addButton
        }
    }
    
    //MARK: - Actions
    
    func save() {
        
    }
    
    func undo() {
        
    }

    func delete(_ data: HeightMeasurement) {
        if data.isFromHealthKit {
            deletedHealthKitMeasurements.append(data)
            deletedHealthKitMeasurements.sort()
        }
        measurements.removeAll(where: { $0.id == data.id })
        setIsDirty()
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

    func setIsDirty() {
        isDirty = measurements != MockWeightData
        || !deletedHealthKitMeasurements.isEmpty
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

let MockHeightData: [HeightMeasurement] = [
    .init(UUID(uuidString: "4312C284-45EA-4805-A924-84658496533B")!, Date(fromShortTimeString: "09_42")!, 177.7),
    .init(UUID(uuidString: "637D2E34-1348-4240-9C96-D9A1E8B347B3")!, Date(fromShortTimeString: "12_07")!, 177.2, UUID(uuidString: "5F507BFC-6BCB-4BE6-88B2-3FD4BEFE4556")!),
    .init(UUID(uuidString: "62440554-1DB5-4024-873A-82B4A63C7EA2")!, Date(fromShortTimeString: "13_23")!, 177.2),
]

#Preview("Current") {
    NavigationView {
        HeightForm(healthProvider: MockCurrentProvider)
    }
}

#Preview("Past") {
    NavigationView {
        HeightForm(healthProvider: MockPastProvider)
    }
}
