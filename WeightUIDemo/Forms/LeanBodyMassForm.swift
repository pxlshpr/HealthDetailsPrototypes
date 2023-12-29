import SwiftUI
import SwiftSugar

struct LeanBodyMassData: Hashable {
    let id: Int
    let source: LeanBodyMassSource
    let date: Date
    let value: Double
    
    init(
        _ id: Int,
        _ source: LeanBodyMassSource,
        _ date: Date,
        _ value: Double
    ) {
        self.id = id
        self.source = source
        self.date = date
        self.value = value
    }
    
    var valueString: String {
        "\(value.clean) kg"
    }
    
    var dateString: String {
        date.shortTime
    }
    
    func fatPercentage(forWeight weight: Double) -> Double {
        (((weight - value) / weight) * 100.0).rounded(toPlaces: 1)
    }
}

struct LeanBodyMassForm: View {
    
//    @Environment(\.dismiss) var dismiss

    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24

    @State var dailyValueType: DailyValueType = .average
    @State var value: Double? = 73.6

    @State var isSynced: Bool = true
    @State var showingSyncOffConfirmation: Bool = false

    @State var showingForm = false
    
    @State var source: LeanBodyMassSource = .userEntered
    
    let pastDate: Date?
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool

    @State var listData: [LeanBodyMassData] = [
        .init(1, .userEntered, Date(fromTimeString: "09_42")!, 73.7),
        .init(2, .healthKit, Date(fromTimeString: "12_07")!, 74.6),
        .init(3, .fatPercentage, Date(fromTimeString: "13_23")!, 72.3),
        .init(4, .equation, Date(fromTimeString: "15_01")!, 70.9),
        .init(5, .userEntered, Date(fromTimeString: "17_35")!, 72.5),
    ]
    
    init(pastDate: Date? = nil, isPresented: Binding<Bool> = .constant(true)) {
        self.pastDate = pastDate
        _isPresented = isPresented
        _isEditing = State(initialValue: pastDate == nil)
    }
    
    @ViewBuilder
    var body: some View {
        Form {
            notice
//            explanation
            list
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
        .navigationBarBackButtonHidden(isEditing && isPast)
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            bottomToolbarContent(
                value: value,
                valueString: value?.clean,
                isDisabled: !isEditing,
                unitString: "kg"
            )
            topToolbarContent(
                isEditing: $isEditing,
                isDirty: $isDirty,
                isPast: isPast,
                dismissAction: { isPresented = false },
                undoAction: undo,
                saveAction: save
            )
        }
    }
    
    func undo() {
    }
    
    func save() {
        
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
        var picker: some View {
            Picker("", selection: $dailyValueType) {
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
            
            return "When multiple values are present, the \(name) is used for the day."

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
            Section(footer: Text("Automatically imports your Lean Body Mass data from Apple Health. Data you add here will also be exported back to Apple Health.")) {
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
    
    func cell(for listData: LeanBodyMassData) -> some View {
        
        @ViewBuilder
        var image: some View {
            switch listData.source {
            case .healthKit:
                Image("AppleHealthIcon")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(.systemGray3), lineWidth: 0.5)
                    )
            default:
                Image(systemName: listData.source.image)
                    .scaleEffect(listData.source.scale)
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
            image
            Text(listData.dateString)
            Spacer()
            Text(listData.valueString)
        }
    }
    
    var list: some View {
        var cells: some View {
            ForEach(listData, id: \.self) { data in
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
        
        return Section {
            cells
            addButton
        }
    }
    
    func delete(at offsets: IndexSet) {

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
