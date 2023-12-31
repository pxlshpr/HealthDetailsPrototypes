import SwiftUI
import SwiftSugar

struct AgeForm: View {
    
    @Bindable var provider: HealthProvider
    
    @State var years: Int?
    @State var dateOfBirth: Date
    @State var customInput: IntInput

    @State var showingAgeAlert = false
    @State var showingDateOfBirthAlert = false
    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24

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
        
        let years = provider.healthDetails.age?.years
        _years = State(initialValue: years)
        _customInput = State(initialValue: IntInput(int: years))
        
        let dateOfBirth = provider.healthDetails.age?.dateOfBirth
        _dateOfBirth = State(initialValue: dateOfBirth ?? DefaultDateOfBirth)
    }
    
    var pastDate: Date? {
        provider.pastDate
    }
    
    var body: some View {
        Form {
            notice
            Group {
                healthSection
                dateOfBirthSection
                customSection
            }
            .disabled(isDisabled)
            explanation
        }
        .navigationTitle("Age")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .alert("Enter your age", isPresented: $showingAgeAlert) {
            TextField("Enter your age", text: customInput.binding)
                .keyboardType(.numberPad)
            Button("OK", action: submitAge)
            Button("Cancel") { }
        }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isPast && isEditing)
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
            let age = dateOfBirth.age
            self.years = age
            customInput.setNewValue(age)
        }
    }
    
    var bottomValue: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Spacer()
            if let years {
                Text("\(years)")
                    .contentTransition(.numericText(value: Double(years)))
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
            isPast: isPast,
            dismissAction: { isPresented = false },
            undoAction: undo,
            saveAction: save
        )
    }
    
    func setIsDirty() {
        isDirty = years != nil
        || dateOfBirth != DefaultDateOfBirth
    }
    
    func setDismissDisabled() {
        dismissDisabled = isPast && isEditing && isDirty
    }

    func undo() {
        let years = provider.healthDetails.age?.years
        self.years = years
        customInput = IntInput(int: years)
        
        let dateOfBirth = provider.healthDetails.age?.dateOfBirth
        self.dateOfBirth = dateOfBirth ?? DefaultDateOfBirth
    }
    
    func handleChanges() {
        setIsDirty()
        if !isPast {
            save()
        }
    }
    
    var age: HealthDetails.Age? {
        guard let years else { return nil }
        return HealthDetails.Age(
            value: years, dateOfBirth: dateOfBirth
        )
    }
    
    func save() {
        provider.saveAge(age)
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
    
    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: $isEditing)
        }
    }
    
    func submitAge() {
        withAnimation {
            customInput.submitValue()
            years = customInput.int
            if let years {
                dateOfBirth = years.dateOfBirth
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
            Button {
                setDateOfBirth(DefaultDateOfBirth)
                handleChanges()
            } label: {
                HStack {
                    Text("Read from Apple Health")
                    Spacer()
                    Image("AppleHealthIcon")
                        .resizable()
                        .frame(width: imageScale * scale, height: imageScale * scale)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color(.systemGray3), lineWidth: 0.5)
                        )
                }
            }
        }
    }
    
    var dateOfBirthSection: some View {
        Section {
            Button {
                showingDateOfBirthAlert = true
            } label: {
                HStack {
                    if years == nil {
                        Text("Choose Date of Birth")
                    } else {
                        Text("Date of Birth")
                            .foregroundStyle(Color(.label))
                    }
                    Spacer()
                    if years != nil {
                        Text(dateOfBirth.shortDateString)
                            .foregroundStyle(Color(.label))
                    }
                    Image(systemName: "calendar")
                        .frame(width: imageScale * scale, height: imageScale * scale)
                }
            }
        }
    }
    
    var customSection: some View {
        Section {
            Button {
                showingAgeAlert = true
            } label: {
                HStack {
                    if years == nil {
                        Text("Set Age")
                    } else {
                        Text("Age")
                            .foregroundStyle(Color(.label))
                    }
                    Spacer()
                    if let years {
                        Text("\(years)")
                            .foregroundStyle(Color(.label))
                    }
                    Image(systemName: "pencil")
                        .frame(width: imageScale * scale, height: imageScale * scale)
                }
            }
        }
    }
}

#Preview("Current") {
    NavigationView {
        AgeForm(provider: MockCurrentProvider)
    }
}

#Preview("Past") {
    NavigationView {
        AgeForm(provider: MockPastProvider)
    }
}

#Preview("DemoView") {
    DemoView()
}
