import SwiftUI
import SwiftSugar

struct SexForm: View {
    
    @State var sex: Sex = .other
    
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
            picker
            explanation
        }
        .navigationTitle("Biological Sex")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isPast && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: $isEditing)
        }
    }
    
    var bottomValue: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Spacer()
            ZStack {
                
                /// dummy text placed to ensure height stays consistent
                Text("0")
                    .font(LargeNumberFont)
                    .opacity(0)

                Text(sex != .other ? sex.name : "Not Set")
                    .font(LargeUnitFont)
//                    .font(sex == .other ? LargeUnitFont : LargeNumberFont)
                    .foregroundStyle(sex != .other ? .primary : .secondary)
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
    
    func setIsDirty() {
        isDirty = sex != .other
    }
    
    func setDismissDisabled() {
        dismissDisabled = isPast && isEditing && isDirty
    }

    func undo() {
    }
    
    func save() {
        
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
    
    var explanation: some View {
        var header: some View {
            Text("Usage")
                .formTitleStyle()
        }

        return Section(header: header) {
            VStack(alignment: .leading) {
                Text("Your biological sex is used when:")
                dotPoint("Calculating your Resting Energy or Lean Body Mass.")
                dotPoint("Assigning nutrient Recommended Daily Allowances.")
            }
        }
    }

    var picker: some View {
        let binding = Binding<Sex>(
            get: { sex },
            set: { newValue in
                self.sex = newValue
                setIsDirty()
            }
        )
        return PickerSection(
            [Sex.female, Sex.male],
            binding,
            isDisabled: Binding<Bool>(
                get: { isDisabled },
                set: { _ in }
            )
        )
    }
}

#Preview("Current") {
    NavigationView {
        SexForm()
    }
}

#Preview("Past") {
    NavigationView {
        SexForm(pastDate: MockPastDate)
    }
}
