import SwiftUI
import SwiftSugar

struct BiologicalSexForm: View {
    
    let date: Date
    let initialBiologicalSex: BiologicalSex

    @State var biologicalSex: BiologicalSex
    
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool
    
    let saveHandler: (BiologicalSex) -> ()

    init(
        date: Date,
        biologicalSex: BiologicalSex,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false),
        save: @escaping (BiologicalSex) -> ()
    ) {
        self.date = date
        self.initialBiologicalSex = biologicalSex
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: date.isToday)
        
        _biologicalSex = State(initialValue: biologicalSex)
        self.saveHandler = save
    }

    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            biologicalSex: healthProvider.healthDetails.biologicalSex,
            isPresented: isPresented,
            dismissDisabled: dismissDisabled,
            save: healthProvider.saveBiologicalSex
        )
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

                Text(biologicalSex != .notSet ? biologicalSex.name : "Not Set")
                    .font(LargeUnitFont)
//                    .font(sex == .other ? LargeUnitFont : LargeNumberFont)
                    .foregroundStyle(biologicalSex != .notSet ? .primary : .secondary)
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
            isPast: isLegacy,
            dismissAction: { isPresented = false },
            undoAction: undo,
            saveAction: save
        )
    }
    
    func setIsDirty() {
        isDirty = biologicalSex != .notSet
    }
    
    func setDismissDisabled() {
        dismissDisabled = isLegacy && isEditing && isDirty
    }

    func undo() {
        self.biologicalSex = initialBiologicalSex
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
            VStack(alignment: .leading) {
                Text("Your biological sex is used when:")
                dotPoint("Calculating your Resting Energy or Lean Body Mass.")
                dotPoint("Assigning nutrient Recommended Daily Allowances.")
            }
        }
    }

    var picker: some View {
        let binding = Binding<BiologicalSex>(
            get: { biologicalSex },
            set: { newValue in
                self.biologicalSex = newValue
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
        if !isLegacy {
            save()
        }
    }
    
    func save() {
        saveHandler(biologicalSex)
    }
}

#Preview("Current") {
    NavigationView {
        BiologicalSexForm(healthProvider: MockCurrentProvider)
    }
}

#Preview("Past") {
    NavigationView {
        BiologicalSexForm(healthProvider: MockPastProvider)
    }
}

#Preview("DemoView") {
    DemoView()
}
