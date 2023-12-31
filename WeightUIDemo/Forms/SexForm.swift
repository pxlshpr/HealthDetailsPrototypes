import SwiftUI
import SwiftSugar

struct SexForm: View {
    
    @Bindable var provider: HealthProvider
    @State var sex: BiologicalSex
    
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
        
        _sex = State(initialValue: provider.healthDetails.sex)
    }

    var pastDate: Date? {
        provider.pastDate
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

                Text(sex != .notSet ? sex.name : "Not Set")
                    .font(LargeUnitFont)
//                    .font(sex == .other ? LargeUnitFont : LargeNumberFont)
                    .foregroundStyle(sex != .notSet ? .primary : .secondary)
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
        isDirty = sex != .notSet
    }
    
    func setDismissDisabled() {
        dismissDisabled = isPast && isEditing && isDirty
    }

    func undo() {
        self.sex = provider.healthDetails.sex
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
        let binding = Binding<BiologicalSex>(
            get: { sex },
            set: { newValue in
                self.sex = newValue
                handleChanges()
            }
        )
        return PickerSection(
            [BiologicalSex.female, BiologicalSex.male],
            binding,
            isDisabled: Binding<Bool>(
                get: { isDisabled },
                set: { _ in }
            )
        )
    }
    
    func handleChanges() {
        setIsDirty()
        if !isPast {
            save()
        }
    }
    
    func save() {
        provider.saveSex(sex)
    }
}

#Preview("Current") {
    NavigationView {
        SexForm(provider: MockCurrentProvider)
    }
}

#Preview("Past") {
    NavigationView {
        SexForm(provider: MockPastProvider)
    }
}

#Preview("DemoView ") {
    DemoView()
}
