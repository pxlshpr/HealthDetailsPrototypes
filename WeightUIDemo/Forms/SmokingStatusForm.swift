import SwiftUI
import SwiftSugar

struct SmokingStatusForm: View {
    
    let date: Date
    let initialSmokingStatus: SmokingStatus

    @State var smokingStatus: SmokingStatus = .notSet
    
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool
    
    let saveHandler: (SmokingStatus) -> ()
    
    init(
        date: Date,
        smokingStatus: SmokingStatus,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false),
        save: @escaping (SmokingStatus) -> ()
    ) {
        self.date = date
        self.initialSmokingStatus = smokingStatus
        self.saveHandler = save
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: date.isToday)
        
        _smokingStatus = State(initialValue: initialSmokingStatus)
    }
    
    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            smokingStatus: healthProvider.healthDetails.smokingStatus,
            isPresented: isPresented,
            dismissDisabled: dismissDisabled,
            save: healthProvider.saveSmokingStatus
        )
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
                handleChanges()
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
            isPast: isLegacy,
            dismissAction: { isPresented = false },
            undoAction: undo,
            saveAction: save
        )
    }
    
    func setIsDirty() {
        isDirty = smokingStatus != .notSet
    }
    
    func setDismissDisabled() {
        dismissDisabled = isLegacy && isEditing && isDirty
    }

    func undo() {
        self.smokingStatus = initialSmokingStatus
    }
    
    func handleChanges() {
        setIsDirty()
        if !isLegacy {
            save()
        }
    }
    
    func save() {
        saveHandler(smokingStatus)
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
            Text("Your smoking status may be used when picking daily values for micronutrients.\n\nFor example, if you are a smoker then the recommended daily allowance of Vitamin C will be slightly higher.")
        }
    }

}

#Preview("Current") {
    NavigationView {
        SmokingStatusForm(healthProvider: MockCurrentProvider)
    }
}

#Preview("Past") {
    NavigationView {
        SmokingStatusForm(healthProvider: MockPastProvider)
    }
}

#Preview("DemoView ") {
    DemoView()
}
