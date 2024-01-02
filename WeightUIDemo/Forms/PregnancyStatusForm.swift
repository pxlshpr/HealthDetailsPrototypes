import SwiftUI
import SwiftSugar

struct PregnancyStatusForm: View {

    let date: Date
    let initialPregnancyStatus: PregnancyStatus

    @State var pregnancyStatus: PregnancyStatus = .notSet

    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool
    
    let saveHandler: (PregnancyStatus) -> ()

    init(
        date: Date,
        pregnancyStatus: PregnancyStatus,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false),
        save: @escaping (PregnancyStatus) -> ()
    ) {
        self.date = date
        self.initialPregnancyStatus = pregnancyStatus
        self.saveHandler = save
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: date.isToday)
        
        _pregnancyStatus = State(initialValue: pregnancyStatus)
    }
    
    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            pregnancyStatus: healthProvider.healthDetails.pregnancyStatus,
            isPresented: isPresented,
            dismissDisabled: dismissDisabled,
            save: healthProvider.savePregnancyStatus
        )
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
        .navigationBarBackButtonHidden(isLegacy && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    @ViewBuilder
    var notice: some View {
        if isLegacy {
            NoticeSection.legacy(date, isEditing: $isEditing)
        }
    }

    var picker: some View {
        let binding = Binding<PregnancyStatus>(
            get: { pregnancyStatus },
            set: { newValue in
                self.pregnancyStatus = newValue
                handleChanges()
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
            isPast: isLegacy,
            dismissAction: { isPresented = false },
            undoAction: undo,
            saveAction: save
        )
    }

    func setIsDirty() {
        isDirty = pregnancyStatus != .notSet
    }
    
    func setDismissDisabled() {
        dismissDisabled = isLegacy && isEditing && isDirty
    }

    func undo() {
        self.pregnancyStatus = initialPregnancyStatus
    }
    
    func handleChanges() {
        setIsDirty()
        if !isLegacy {
            save()
        }
    }
    
    func save() {
        saveHandler(pregnancyStatus)
    }

    var isDisabled: Bool {
        isLegacy && !isEditing
    }
    
    var controlColor: Color {
        isDisabled ? .secondary : .primary
    }
    
    var isLegacy: Bool {
        date.startOfDay < Date.now.startOfDay
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
        PregnancyStatusForm(healthProvider: MockCurrentProvider)
    }
}

#Preview("Past") {
    NavigationView {
        PregnancyStatusForm(healthProvider: MockPastProvider)
    }
}
