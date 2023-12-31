import SwiftUI
import SwiftSugar

struct WeightForm: View {
    
    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24
    
    @State var dailyValueType: DailyValueType = .average
    @State var value: Double? = 93.6
    
    @State var isSynced: Bool = true
    @State var showingSyncOffConfirmation: Bool = false
    
    @State var listData: [MeasurementData] = MockWeightData
    @State var deletedHealthData: [MeasurementData] = []
    
    @State var showingForm = false

    let pastDate: Date?
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool
    
    init(
        pastDate: Date? = nil,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.pastDate = pastDate
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: pastDate == nil)
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
    
    func cell(for data: MeasurementData, disabled: Bool = false) -> some View {
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
            Text(data.valueString(unit: "kg"))
                .foregroundStyle(disabled ? .secondary : .primary)
        }
    }
    
    var list: some View {
        var footer: some View {
            Text(dailyValueType.description)
        }
        
        @ViewBuilder
        var addButton: some View {
            if !isDisabled {
                Button {
                    showingForm = true
                } label: {
                    Text("Add Measurement")
                }
            }
        }
        
        var cells: some View {
            ForEach(listData) { data in
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
    
    var measurementForm: some View {
        MeasurementForm(healthDetail: .weight, date: pastDate)
    }

    var bottomValue: some View {
        var bottomRow: some View {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Spacer()
                if let value {
                    Text("\(value.roundedToOnePlace)")
                        .contentTransition(.numericText(value: value))
                        .font(LargeNumberFont)
                        .foregroundStyle(isDisabled ? .secondary : .primary)
                    Text("kg")
                        .font(LargeUnitFont)
                        .foregroundStyle(isDisabled ? .tertiary : .secondary)
                } else {
                    ZStack {

                        /// dummy text placed to ensure height stays consistent
                        Text("0")
                            .font(LargeNumberFont)
                            .opacity(0)
                        
                        Text("Not Set")
                            .font(LargeUnitFont)
                            .foregroundStyle(isDisabled ? .tertiary : .secondary)
                    }
                }
            }
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
    
    var deletedList: some View {
        var header: some View {
            Text("Ignored Apple Health Data")
        }
        
        func restore(_ data: MeasurementData) {
            withAnimation {
                listData.append(data)
                listData.sort()
                deletedHealthData.removeAll(where: { $0.id == data.id })
            }
        }
        return Group {
            if !deletedHealthData.isEmpty {
                Section(header: header) {
                    ForEach(deletedHealthData) { data in
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
                    setIsDirty()
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
            set: {
                if !$0 {
                    showingSyncOffConfirmation = true
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
        isDirty = listData != MockWeightData
        || !deletedHealthData.isEmpty
        || dailyValueType != .average
    }
    
    func setDismissDisabled() {
        dismissDisabled = isPast && isEditing && isDirty
    }

    func undo() {
    }
    
    func save() {
        
    }

    func delete(_ data: MeasurementData) {
        if data.isFromHealthKit {
            deletedHealthData.append(data)
            deletedHealthData.sort()
        }
        listData.removeAll(where: { $0.id == data.id })
        setIsDirty()
    }
    
    func delete(at offsets: IndexSet) {
        let dataToDelete = offsets.map { self.listData[$0] }
        withAnimation {
            for data in dataToDelete {
                delete(data)
            }
        }
    }
}

let MockWeightData: [MeasurementData] = [
    .init(1, Date(fromTimeString: "09_42")!, 95.4),
    .init(2, Date(fromTimeString: "12_07")!, 94.4, UUID(uuidString: "5F507BFC-6BCB-4BE6-88B2-3FD4BEFE4556")!),
    .init(3, Date(fromTimeString: "13_23")!, 94.3),
    .init(4, Date(fromTimeString: "15_01")!, 94.7, UUID(uuidString: "9B12AB6D-69DA-4FAC-9D80-3D0BB6A67D50")!),
    .init(5, Date(fromTimeString: "17_35")!, 95.1),
    .init(6, Date(fromTimeString: "19_54")!, 94.5),
]

#Preview("Current") {
    NavigationView {
        WeightForm()
    }
}

#Preview("Past") {
    NavigationView {
        WeightForm(pastDate: MockPastDate)
    }
}

#Preview {
    DemoView()
}
