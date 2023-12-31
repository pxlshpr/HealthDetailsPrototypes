import SwiftUI
import SwiftSugar

struct AgeForm: View {
    
    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24
    
    @State var showingAgeAlert = false
    @State var showingDateOfBirthAlert = false

    @State var age: Int? = nil
    
    @State var dateOfBirth = DefaultDateOfBirth
    @State var chosenDateOfBirth = DefaultDateOfBirth
    @State var customInput = IntInput()

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
            Group {
                healthSection
                dateOfBirthSection
                customSection
            }
            explanation
            .disabled(isDisabled)
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
        .sheet(isPresented: $showingDateOfBirthAlert) {
            NavigationView {
                DatePicker(
                    "Date of Birth",
                    selection: $chosenDateOfBirth,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .navigationTitle("Date of Birth")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            setDateOfBirth(chosenDateOfBirth)
                            showingDateOfBirthAlert = false
                        }
                        .fontWeight(.semibold)
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            chosenDateOfBirth = dateOfBirth
                            showingDateOfBirthAlert = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    func setDateOfBirth(_ dateOfBirth: Date) {
        self.dateOfBirth = dateOfBirth
        withAnimation {
            let age = dateOfBirth.age
            self.age = age
            customInput.setNewValue(age)
        }
    }
    
    var bottomValue: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Spacer()
            if let age {
                Text("\(age)")
                    .contentTransition(.numericText(value: Double(age)))
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
        isDirty = age != nil
        || dateOfBirth != DefaultDateOfBirth
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
    
    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: $isEditing)
        }
    }
    
    func submitAge() {
        withAnimation {
            customInput.submitValue()
            age = customInput.int
            if let age {
                dateOfBirth = age.dateOfBirth
                chosenDateOfBirth = age.dateOfBirth
            }
            setIsDirty()
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
        .init(false, "9:42 am", "93.7 kg"),
        .init(true, "12:07 pm", "94.6 kg"),
        .init(false, "5:35 pm", "92.5 kg"),
    ]
    
    func cell(for listData: ListData) -> some View {
        HStack {
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
            Text(listData.dateString)
            
            Spacer()
            Text(listData.valueString)
        }
    }
        
    var healthSection: some View {
        Section {
            Button {
                self.setDateOfBirth(DefaultDateOfBirth)
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
                    Text("Choose Date of Birth")
                    Spacer()
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
                    Text("Enter Age")
                    Spacer()
                    Image(systemName: "keyboard")
                        .frame(width: imageScale * scale, height: imageScale * scale)
                }
            }
        }
    }
}

#Preview("Current") {
    NavigationView {
        AgeForm()
    }
}

#Preview("Past") {
    NavigationView {
        AgeForm(pastDate: MockPastDate)
    }
}
