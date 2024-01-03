import SwiftUI
import SwiftSugar

struct AgeForm: View {
    
    let date: Date
    let initialDateOfBirth: Date?

    @State var ageInYears: Int?
    @State var dateOfBirth: Date
    @State var customInput: IntInput

    @State var showingAgeAlert = false
    @State var showingDateOfBirthAlert = false

    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool
    
    let saveHandler: (Date?) -> ()

    init(
        date: Date,
        dateOfBirth: Date?,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false),
        save: @escaping (Date?) -> ()
    ) {
        self.date = date
        self.initialDateOfBirth = dateOfBirth
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: date.isToday)
        
        let ageInYears = dateOfBirth?.ageInYears
        _ageInYears = State(initialValue: ageInYears)
        _customInput = State(initialValue: IntInput(int: ageInYears))
        
        _dateOfBirth = State(initialValue: dateOfBirth ?? DefaultDateOfBirth)
        
        self.saveHandler = save
    }
    
    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            dateOfBirth: healthProvider.healthDetails.dateOfBirth,
            isPresented: isPresented,
            dismissDisabled: dismissDisabled,
            save: healthProvider.saveDateOfBirth
        )
    }
    var body: some View {
        Form {
            notice
            Group {
                healthSection
                dateOfBirthSection
                customSection
            }
            explanation
        }
        .navigationTitle("Age")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .alert("Enter your age", isPresented: $showingAgeAlert) {
            TextField("Age in years", text: customInput.binding)
                .keyboardType(.numberPad)
            Button("OK", action: submitAge)
            Button("Cancel") { }
        }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isLegacy && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
        .sheet(isPresented: $showingDateOfBirthAlert) { datePickerSheet }
    }
    
    var datePickerSheet: some View {
        DatePickerSheet("Date of Birth", Binding<Date>(
            get: { self.dateOfBirth },
            set: { newValue in
                setDateOfBirth(newValue)
                handleChanges()
            }
        ))
    }
    
    func setDateOfBirth(_ dateOfBirth: Date) {
        self.dateOfBirth = dateOfBirth
        withAnimation {
            let age = dateOfBirth.ageInYears
            self.ageInYears = age
            customInput.setNewValue(age)
        }
    }
    
    var bottomValue: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Spacer()
            if let ageInYears {
                Text("\(ageInYears)")
                    .contentTransition(.numericText(value: Double(ageInYears)))
                    .font(LargeNumberFont)
                Text("years")
                    .font(LargeUnitFont)
                    .foregroundStyle(.secondary)
            } else {
                ZStack {
                    
                    /// dummy text placed to ensure height stays consistent
                    Text("0")
                        .font(LargeNumberFont)
                        .opacity(0)

                    Text("Not Set")
                        .font(NotSetFont)
                        .foregroundStyle(.secondary)
                }
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
        isDirty = ageInYears != nil
        || dateOfBirth != DefaultDateOfBirth
    }
    
    func setDismissDisabled() {
        dismissDisabled = isLegacy && isEditing && isDirty
    }

    func undo() {
        self.dateOfBirth = initialDateOfBirth ?? DefaultDateOfBirth
        self.ageInYears = initialDateOfBirth?.ageInYears
        customInput = IntInput(int: ageInYears)
    }
    
    func handleChanges() {
        setIsDirty()
        if !isLegacy {
            save()
        }
    }
    
    func save() {
        let dateOfBirth = ageInYears != nil ? self.dateOfBirth : nil
        saveHandler(dateOfBirth)
    }

    var isDisabled: Bool {
        isLegacy && !isEditing
    }
    
    var controlColor: Color {
        isDisabled ? Color(.secondaryLabel) : Color(.label)
    }
    
    var isLegacy: Bool {
        date.startOfDay < Date.now.startOfDay
    }
    
    @ViewBuilder
    var notice: some View {
        if isLegacy {
            NoticeSection.legacy(date, isEditing: $isEditing)
        }
    }
    
    func submitAge() {
        withAnimation {
            customInput.submitValue()
            ageInYears = customInput.int
            if let ageInYears {
                dateOfBirth = ageInYears.dateOfBirth
            }
            handleChanges()
        }
    }
    
    var explanation: some View {
        var header: some View {
            Text("Usage")
                .formTitleStyle()
        }

        return Section(header: header) {
            VStack(alignment: .leading) {
                Text("Your age is used when:")
                dotPoint("Calculating your Resting Energy.")
                dotPoint("Assigning nutrient Recommended Daily Allowances.")
            }
        }
    }
        
    var healthSection: some View {
        Section {
            HStack {
                Text("Import from Apple Health")
                    .foregroundStyle(isDisabled ? Color(.secondaryLabel) : Color.accentColor)
                Spacer()
                Button {
                    setDateOfBirth(DefaultDateOfBirth)
                    handleChanges()
                } label: {
                    AppleHealthIcon()
//                    Image("AppleHealthIcon")
//                        .grayscale(isDisabled ? 1 : 0)
                }
                .disabled(isDisabled)
            }
        }
    }
    
    var dateOfBirthSection: some View {
        Section {
            HStack {
                if ageInYears == nil {
                    Text("Set Date of Birth")
                        .foregroundStyle(Color.accentColor)
                } else {
                    Text("Date of Birth")
                        .foregroundStyle(controlColor)
                }
                Spacer()
                if ageInYears != nil {
                    Text(dateOfBirth.shortDateString)
                        .foregroundStyle(controlColor)
                }
                Button {
                    showingDateOfBirthAlert = true
                } label: {
                    ScalableIcon(systemName: "calendar")
//                    Image(systemName: "calendar")
//                        .frame(width: imageScale * scale, height: imageScale * scale)
                }
                .disabled(isDisabled)
            }
        }
    }
    
    var customSection: some View {
        Section {
            HStack {
                if ageInYears == nil {
                    Text("Set Age")
                        .foregroundStyle(Color.accentColor)
                } else {
                    Text("Age")
                        .foregroundStyle(controlColor)
                }
                Spacer()
                if let ageInYears {
                    Text("\(ageInYears)")
                        .foregroundStyle(controlColor)
                }
                Button {
                    showingAgeAlert = true
                } label: {
                    ScalableIcon(systemName: "pencil")
//                    Image(systemName: "pencil")
//                        .frame(width: imageScale * scale, height: imageScale * scale)
                }
                .disabled(isDisabled)
            }
        }
    }
}

#Preview("Current") {
    NavigationView {
        AgeForm(healthProvider: MockCurrentProvider)
    }
}

#Preview("Past") {
    NavigationView {
        AgeForm(healthProvider: MockPastProvider)
    }
}

#Preview("DemoView ") {
    DemoView()
}
