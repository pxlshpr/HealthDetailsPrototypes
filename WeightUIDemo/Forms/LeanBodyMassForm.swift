import SwiftUI
import SwiftSugar

let MockLeanBodyMassData: [LeanBodyMassData] = [
    .init(1, .userEntered, Date(fromTimeString: "09_42")!, 73.7),
    .init(2, .healthKit, Date(fromTimeString: "12_07")!, 74.6),
    .init(3, .fatPercentage, Date(fromTimeString: "13_23")!, 72.3),
    .init(4, .equation, Date(fromTimeString: "15_01")!, 70.9),
    .init(5, .userEntered, Date(fromTimeString: "17_35")!, 72.5),
    .init(6, .healthKit, Date(fromTimeString: "19_54")!, 74.2),
]

struct LeanBodyMassForm: View {
    
    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24

    @State var dailyValueType: DailyValueType = .average
    @State var value: Double? = 73.6
    @State var fatPercentage: Double? = 22.4
    
    @State var isSynced: Bool = true
    @State var showingSyncOffConfirmation: Bool = false

    @State var showingForm = false
    
    @State var source: LeanBodyMassSource = .userEntered

    @State var listData: [LeanBodyMassData] = MockLeanBodyMassData
    
    @State var deletedHealthData: [LeanBodyMassData] = []
    
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
            notice
//            explanation
            list
            deletedList
            dailyValuePicker
            syncSection
        }
        .navigationTitle("Lean Body Mass")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .confirmationDialog("Turn Off Sync", isPresented: $showingSyncOffConfirmation, titleVisibility: .visible) {
            Button("Turn Off", role: .destructive) {
                
            }
        } message: {
            Text("Lean body mass data will no longer be read from or written to Apple Health.")
        }
        .sheet(isPresented: $showingForm) { measurementForm }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isPast && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    func setDismissDisabled() {
        dismissDisabled = isPast && isEditing && isDirty
    }

    var bottomValue: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
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
        .padding(.horizontal, BottomValueHorizontalPadding)
        .padding(.vertical, BottomValueVerticalPadding)
        .background(.bar)
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
    
    func undo() {
    }
    
    func save() {
        
    }
    
    func setIsDirty() {
        isDirty = listData != MockLeanBodyMassData
        || !deletedHealthData.isEmpty
        || dailyValueType != .average
    }

    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: $isEditing)
        }
    }

    var measurementForm: some View {
        LeanBodyMassMeasurementForm()
    }
    
    var isDisabled: Bool {
        isPast && !isEditing
    }
    
    var controlColor: Color {
        isDisabled ? .secondary : .primary
    }
    
    var isPast: Bool {
        pastDate != nil
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
        
        var picker: some View {
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
            let name = switch dailyValueType {
            case .average:  "average"
            case .last:     "last value"
            case .first:    "first value"
            }
            
            return "When multiple values are present, use the \(name) of the day."

        }
        return Section("Daily Value") {
            picker
            Text(description)
        }
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
            Section(footer: Text("Automatically imports your Lean Body Mass and Body Fat Percentage data from Apple Health. Data you add here will also be exported back to Apple Health.")) {
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
    
    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Your lean body mass is the weight of your body minus your body fat (adipose tissue). It may be used when:")
                dotPoint("Creating goals. For example, you could create a protein goal relative to your lean body mass instead of your weight.")
                dotPoint("Calculating your estimated resting energy.")
            }
        }
    }
    
    func cell(for data: LeanBodyMassData, disabled: Bool = false) -> some View {
        
        @ViewBuilder
        var image: some View {
            switch data.source {
            case .healthKit:
                Image("AppleHealthIcon")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(.systemGray3), lineWidth: 0.5)
                    )
            default:
                Image(systemName: data.source.image)
                    .scaleEffect(data.source.scale)
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
                    delete(data)
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
            Text("23%")
                .foregroundStyle(disabled ? .tertiary : .secondary)
            Text(data.valueString)
                .foregroundStyle(disabled ? .secondary : .primary)
        }
    }

    var deletedList: some View {
        var header: some View {
            Text("Ignored Apple Health Data")
        }
        
        func restore(_ data: LeanBodyMassData) {
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
    
    var list: some View {
        var cells: some View {
            ForEach(listData) { data in
                cell(for: data)
                    .deleteDisabled(isPast)
            }
            .onDelete(perform: delete)
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

        var footer: some View {
            Text("Percentages indicate your body fat.")
        }
        return Section(footer: footer) {
            cells
            addButton
        }
    }
    
    func delete(_ data: LeanBodyMassData) {
        if data.source == .healthKit {
            deletedHealthData.append(data)
            deletedHealthData.sort()
        }
        listData.removeAll(where: { $0.id == data.id })
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

#Preview("Current") {
    NavigationView {
        LeanBodyMassForm()
    }
}

#Preview("Past") {
    NavigationView {
        LeanBodyMassForm(pastDate: MockPastDate)
    }
}
