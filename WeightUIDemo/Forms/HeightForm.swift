import SwiftUI
import SwiftSugar

struct HeightForm: View {
    
//    @Environment(\.dismiss) var dismiss

    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24

    @State var value: Double? = 177.4

    @State var isSynced: Bool = true
    @State var showingSyncOffConfirmation: Bool = false

    let pastDate: Date?
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool

    init(pastDate: Date? = nil, isPresented: Binding<Bool> = .constant(true)) {
        self.pastDate = pastDate
        _isPresented = isPresented
        _isEditing = State(initialValue: pastDate == nil)
    }

    var body: some View {
        Form {
            notice
            list
            syncToggle
//            explanation
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
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isPast && isEditing)
        .interactiveDismissDisabled(isPast && isEditing && isDirty)
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
    
    func save() {
        
    }
    
    func undo() {
        
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
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: $isEditing)
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
}

//MARK: - Convenience

extension HeightForm {
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
