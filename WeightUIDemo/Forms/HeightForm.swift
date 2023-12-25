import SwiftUI
import SwiftSugar

struct HeightForm: View {
    
    @Environment(\.dismiss) var dismiss

    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24

    @State var value: Double = 177.4

    @State var isSynced: Bool = true
    @State var showingSyncOffConfirmation: Bool = false

    @State var isEditing: Bool
    @State var isDirty: Bool = false

    let mode: Mode
    
    init(mode: Mode = .healthDetails) {
        self.mode = mode
        _isEditing = State(initialValue: !mode.isPast)
    }

    var body: some View {
        Form {
            explanation
            notice
            legacyNotice
            list
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
        .navigationBarBackButtonHidden(isEditing && mode.isPast)
    }
    
    var controlColor: Color {
        isEditing ? Color(.label) : Color(.secondaryLabel)
    }
    
    var isDisabled: Bool {
        !isEditing
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
            if !mode.isPast {
                section
            }
        }
    }
    var toolbarContent: some ToolbarContent {
        Group {
            bottomToolbarContent(
                value: value,
                isDisabled: isDisabled,
                unitString: "cm"
            )
            topToolbarContent(
                isEditing: $isEditing,
                isDirty: $isDirty,
                isPast: mode.isPast,
                dismissAction: { dismiss() },
                undoAction: undo,
                saveAction: save
            )
        }
    }
    
    func save() {
        
    }
    
    func undo() {
        
    }

    @ViewBuilder
    var explanation: some View {
        if mode.showsExplanation {
            Section {
                VStack(alignment: .leading) {
                    Text("Your height may be used when:")
                    dotPoint("Calculating your estimated resting energy.")
                    dotPoint("Calculating your lean body mass.")
                }
            }
        }
    }

    @ViewBuilder
    var notice: some View {
        if let notice = mode.notice {
            NoticeSection(style: .plain, notice: notice)
        }
    }

    @ViewBuilder
    var legacyNotice: some View {
        if mode.isPast, !isEditing, let notice = mode.legacyNotice {
            NoticeSection(style: .plain, notice: notice)
        }
    }
    
    struct ListData: Hashable {
        let isHealth: Bool
        let dateString: String
        let valueString: String
        
        init(_ isHealth: Bool, _ dateString: String, _ valueString: String) {
            self.isHealth = isHealth
            self.dateString = dateString
            self.valueString = valueString
        }
    }
    
    let listData: [ListData] = [
        .init(false, "9:42 am", "117.3 cm"),
        .init(true, "12:07 pm", "117.6 cm"),
        .init(false, "5:35 pm", "117.4 cm"),
    ]

    func cell(for listData: ListData) -> some View {
        @ViewBuilder
        var image: some View {
            if listData.isHealth {
                Image("AppleHealthIcon")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(.systemGray3), lineWidth: 0.5)
                    )
            } else {
                Image(systemName: "pencil")
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundStyle(Color(.systemGray4))
                    )
            }
        }
        
        return HStack {
            image
                .opacity(isEditing ? 1 : 0.6)
            Text(listData.dateString)
            Spacer()
            Text(listData.valueString)
        }
        .foregroundStyle(controlColor)
    }
    
    var list: some View {
        var bottomContent: some View {
            
            var isEmpty: Bool {
                listData.isEmpty
            }
            
            var label: String {
                isEditing ? "Add Measurement" : "Not Set"
            }
            
            var color: Color {
                isEditing ? Color.accentColor : Color(.tertiaryLabel)
            }
            var button: some View {
                Button {
                    
                } label: {
                    Text(label)
                        .foregroundStyle(color)
                }
                .disabled(!isEditing)
            }
            
            return Group {
                if isEditing || isEmpty {
                    button
                }
            }
        }
        
        var footer: some View {
            //TODO: Only show if multiple values are present
            Text("The latest measurement is always used.")
        }
        
        return Group {
            Section(footer: footer) {
                ForEach(listData, id: \.self) {
                    cell(for: $0)
                        .deleteDisabled($0.isHealth)
                }
                .onDelete(perform: delete)
                bottomContent
            }
        }
    }
    
    func delete(at offsets: IndexSet) {

    }
    
    enum Mode {
        case healthDetails
        case pastHealthDetails
        case restingEnergyVariable
        case pastRestingEnergyVariable
        case leanBodyMassVariable
        case pastLeanBodyMassVariable
        
        var showsExplanation: Bool {
            switch self {
            case .healthDetails:    true
            default:                false
            }
        }
        
        var isPast: Bool {
            switch self {
            case .pastHealthDetails, .pastRestingEnergyVariable, .pastLeanBodyMassVariable:
                true
            default:
                false
            }
        }
        
        var legacyNotice: Notice? {
            switch self {
            case .pastHealthDetails:
                .legacy
            case .pastRestingEnergyVariable:
                Notice(
                    title: "Legacy Data",
                    message: "This data has been preserved to ensure that your Resting Energy calculation remains unchanged.",
                    imageName: "calendar.badge.clock"
                )
            case .pastLeanBodyMassVariable:
                Notice(
                    title: "Legacy Data",
                    message: "This data has been preserved to ensure any goals set on this day remain unchanged.",
                    imageName: "calendar.badge.clock"
                )
            default:
                nil
            }
        }
        
        var notice: Notice? {
            switch self {
            case .restingEnergyVariable, .pastRestingEnergyVariable:
                Notice(
                    title: "Equation Variable",
                    message: "This is used as a variable for the equation calculating your Resting Energy.",
                    imageName: "function"
                )
            case .leanBodyMassVariable, .pastLeanBodyMassVariable:
                Notice(
                    title: "Equation Variable",
                    message: "This is used as a variable for the equation calculating your Lean Body Mass.",
                    imageName: "function"
                )
            default:
                nil
            }
        }
    }
}

#Preview("Health Details") {
    NavigationStack {
        HeightForm(mode: .healthDetails)
    }
}

#Preview("Past Health Details") {
    NavigationStack {
        HeightForm(mode: .pastHealthDetails)
    }
}

#Preview("Lean Body Mass Variable") {
    NavigationStack {
        HeightForm(mode: .leanBodyMassVariable)
    }
}

#Preview("Past Lean Body Mass Variable") {
    NavigationStack {
        HeightForm(mode: .pastLeanBodyMassVariable)
    }
}

#Preview("Resting Energy Variable") {
    NavigationStack {
        HeightForm(mode: .restingEnergyVariable)
    }
}

#Preview("Past Resting energy Variable") {
    NavigationStack {
        HeightForm(mode: .pastRestingEnergyVariable)
    }
}
