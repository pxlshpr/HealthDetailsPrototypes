import SwiftUI
import SwiftSugar

struct PregnancyStatusForm: View {

    @State var pregnancyStatus: PregnancyStatus = .notSet

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
        .navigationTitle("Pregnancy Status")
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

    var picker: some View {
        let binding = Binding<PregnancyStatus>(
            get: { pregnancyStatus },
            set: { newValue in
                self.pregnancyStatus = newValue
                setIsDirty()
            }
        )
        return PickerSection(
            [PregnancyStatus.notPregnantOrLactating, PregnancyStatus.pregnant, PregnancyStatus.lactating],
            binding,
            isDisabled: Binding<Bool>(
                get: { isDisabled },
                set: { _ in }
            )
        )
        
    }
    var bottomValue: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Spacer()
            Text(pregnancyStatus.name)
                .font(NotSetFont)
                .foregroundStyle(pregnancyStatus == .notSet ? .secondary : .primary)
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
        isDirty = pregnancyStatus != .notSet
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
            Text("Your pregnancy status may be used when picking daily values for micronutrients.\n\nFor example, the recommended daily allowance for Iodine almost doubles when a mother is breastfeeding.")
        }
    }

}

#Preview("Current") {
    NavigationView {
        PregnancyStatusForm()
    }
}

#Preview("Past") {
    NavigationView {
        PregnancyStatusForm(pastDate: MockPastDate)
    }
}
