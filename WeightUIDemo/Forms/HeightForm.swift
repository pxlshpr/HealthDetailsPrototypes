import SwiftUI
import SwiftSugar

struct HeightForm: View {
    
    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24
    
    @State var value: Double? = 177.4
    
    @State var isSynced: Bool = true
    @State var showingSyncOffConfirmation: Bool = false
    
    @State var listData: [MeasurementData] = MockHeightData
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
            syncToggle
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
            value: $value,
            valueString: Binding<String?>(
                get: { value?.clean },
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
        EmptyView()
        //        LeanBodyMassMeasurementForm(date: pastDate)
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
        Section {
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
            Text(data.valueString(unit: "cm"))
                .foregroundStyle(disabled ? .secondary : .primary)
        }
    }
    
    var list: some View {
        var footer: some View {
            Text(DailyValueType.last.description)
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
    
    //MARK: - Actions
    
    func save() {
        
    }
    
    func undo() {
        
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
    func setDismissDisabled() {
        dismissDisabled = isPast && isEditing && isDirty
    }

    func setIsDirty() {
        isDirty = listData != MockWeightData
        || !deletedHealthData.isEmpty
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

let MockHeightData: [MeasurementData] = [
    .init(1, Date(fromTimeString: "09_42")!, 177.7),
    .init(2, Date(fromTimeString: "12_07")!, 177.2, UUID(uuidString: "5F507BFC-6BCB-4BE6-88B2-3FD4BEFE4556")!),
    .init(3, Date(fromTimeString: "13_23")!, 177.2),
]

#Preview("Current") {
    NavigationView {
        HeightForm()
    }
}

#Preview("Past") {
    NavigationView {
        HeightForm(pastDate: MockPastDate)
    }
}
