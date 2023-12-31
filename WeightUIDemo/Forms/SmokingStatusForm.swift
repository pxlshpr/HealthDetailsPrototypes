import SwiftUI
import SwiftSugar

struct SmokingStatusForm: View {
    
    @State var smokingStatus: SmokingStatus = .notSet
    
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
        .navigationTitle("Smoking Status")
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

                Text(smokingStatus.name)
                    .font(NotSetFont)
                    .foregroundStyle(smokingStatus == .notSet ? .secondary : .primary)
            }
        }
        .padding(.horizontal, BottomValueHorizontalPadding)
        .padding(.vertical, BottomValueVerticalPadding)
        .background(.bar)
    }
    
    var picker: some View {
        let binding = Binding<SmokingStatus>(
            get: { smokingStatus },
            set: { newValue in
                self.smokingStatus = newValue
                setIsDirty()
            }
        )
        return PickerSection(
            [SmokingStatus.nonSmoker, SmokingStatus.smoker],
            binding,
            isDisabled: Binding<Bool>(
                get: { isDisabled },
                set: { _ in }
            )
        )
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
        isDirty = smokingStatus != .notSet
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
        Section {
            Text("Your smoking status may be used when picking daily values for micronutrients.\n\nFor example, if you are a smoker then the recommended daily allowance of Vitamin C will be slightly higher.")
        }
    }

}

#Preview("Current") {
    NavigationView {
        SmokingStatusForm()
    }
}

#Preview("Past") {
    NavigationView {
        SmokingStatusForm(pastDate: MockPastDate)
    }
}
