import SwiftUI
import SwiftSugar

struct LeanBodyMassForm: View {
    
    @Bindable var provider: HealthProvider
    
    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24

    @State var dailyValueType: DailyValueType = .average
    @State var value: Double? = 73.6
    @State var fatPercentage: Double? = 22.4
    
    @State var isSynced: Bool = true
    @State var showingSyncOffConfirmation: Bool = false

    @State var showingForm = false
    
    @State var listData: [LeanBodyMassData] = MockLeanBodyMassData
    @State var deletedHealthData: [LeanBodyMassData] = []
    
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    init(
        provider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.provider = provider
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: provider.isCurrent)
    }
    
    var pastDate: Date? {
        provider.pastDate
    }
    
    var body: some View {
        Form {
            noticeOrDateSection
            list
            deletedList
            syncSection
            explanation
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
        var bottomRow: some View {
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

    var measurementForm: some View {
        LeanBodyMassMeasurementForm(provider: provider)
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
            if let fatPercentage = data.fatPercentage {
                Text("\(fatPercentage.roundedToOnePlace)%")
                    .foregroundStyle(disabled ? .tertiary : .secondary)
            }
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
            Text("\(dailyValueType.description) Percentages indicate your body fat.")
        }
        
        return Section(footer: footer) {
            cells
            addButton
        }
    }
    
    func delete(_ data: LeanBodyMassData) {
        if data.source.isFromHealthKit {
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

let MockLeanBodyMassData: [LeanBodyMassData] = [
    .init(1, .userEntered, Date(fromTimeString: "09_42")!, 73.7, 23),
    .init(2, .healthKit(UUID(uuidString: "69BD6FDB-B6B3-4134-B31E-CDA217ACC1CA")!), Date(fromTimeString: "12_07")!, 74.6, 22.8),
    .init(3, .fatPercentage, Date(fromTimeString: "13_23")!, 72.3, 23.9),
    .init(4, .equation, Date(fromTimeString: "15_01")!, 70.9, 24.7),
    .init(5, .userEntered, Date(fromTimeString: "17_35")!, 72.5),
    .init(6, .healthKit(UUID(uuidString: "EE5EB41F-9491-4AC9-93F5-E82443D8C260")!), Date(fromTimeString: "19_54")!, 74.2),
]

#Preview("Current") {
    NavigationView {
        LeanBodyMassForm(provider: MockCurrentProvider)
    }
}

#Preview("Past") {
    NavigationView {
        LeanBodyMassForm(provider: MockPastProvider)
    }
}
