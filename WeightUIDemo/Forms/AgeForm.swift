import SwiftUI
import SwiftSugar

struct AgeForm: View {
    
    @Binding var isPresented: Bool
    let date: Date

    @State var ageInYears: Int?
    @State var dateOfBirth: Date
    @State var manualInput: IntInput

    @State var showingAgeAlert = false
    @State var showingDateOfBirthAlert = false

    let saveHandler: (Date?) -> ()

    @State var healthKitDateOfBirth: Date? = nil
    @State var hasAppeared = false
    
    init(
        date: Date,
        dateOfBirth: Date?,
        isPresented: Binding<Bool> = .constant(true),
        save: @escaping (Date?) -> ()
    ) {
        self.date = date
        _isPresented = isPresented
        
        let ageInYears = dateOfBirth?.ageInYears
        _ageInYears = State(initialValue: ageInYears)
        _manualInput = State(initialValue: IntInput(int: ageInYears))
        
        _dateOfBirth = State(initialValue: dateOfBirth ?? DefaultDateOfBirth)
        
        self.saveHandler = save
    }
    
    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            dateOfBirth: healthProvider.healthDetails.dateOfBirth,
            isPresented: isPresented,
            save: healthProvider.saveDateOfBirth
        )
    }
    var body: some View {
        Form {
//            dateSection
            Group {
                healthSection
                dateOfBirthSection
                manualSection
            }
            explanation
        }
        .navigationTitle("Age")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .alert("Enter your age", isPresented: $showingAgeAlert) {
            TextField("Age in years", text: manualInput.binding)
                .keyboardType(.numberPad)
            Button("OK", action: submitAge)
            Button("Cancel") { }
        }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .sheet(isPresented: $showingDateOfBirthAlert) { datePickerSheet }
        .onAppear(perform: appeared)
    }
    
    func appeared() {
        if !hasAppeared {
            Task {
                await fetchHealthKitValue()
            }
            hasAppeared = true
        }
    }
    
    func fetchHealthKitValue() async {
        let date = try? await HealthStore.dateOfBirthComponents()?.date
        await MainActor.run {
            self.healthKitDateOfBirth = date
        }
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
            manualInput.setNewValue(age)
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

                    Text(NotSetString)
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
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isPresented = false
            } label: {
                CloseButtonLabel()
            }
        }
    }
    
    func handleChanges() {
        save()
    }
    
    func save() {
        let dateOfBirth = ageInYears != nil ? self.dateOfBirth : nil
        saveHandler(dateOfBirth)
    }

    var dateSection: some View {
        Section {
            HStack {
                Text("Date")
                Spacer()
                Text(date.shortDateString)
            }
        }
    }
    
    func submitAge() {
        withAnimation {
            manualInput.submitValue()
            ageInYears = manualInput.int
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
                    .foregroundStyle(Color.accentColor)
                Spacer()
                Button {
                    if let healthKitDateOfBirth {
                        setDateOfBirth(healthKitDateOfBirth)
                    } else {
                        ageInYears = nil
                    }
                    handleChanges()
                } label: {
                    AppleHealthIcon()
                }
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
                        .foregroundStyle(Color(.label))
                }
                Spacer()
                if ageInYears != nil {
                    Text(dateOfBirth.shortDateString)
                        .foregroundStyle(Color(.label))
                }
                Button {
                    showingDateOfBirthAlert = true
                } label: {
                    ScalableIcon(systemName: "calendar")
                }
            }
        }
    }
    
    var manualSection: some View {
        Section {
            HStack {
                if ageInYears == nil {
                    Text("Set Age")
                        .foregroundStyle(Color.accentColor)
                } else {
                    Text("Age")
                        .foregroundStyle(Color(.label))
                }
                Spacer()
                if let ageInYears {
                    Text("\(ageInYears)")
                        .foregroundStyle(Color(.label))
                }
                Button {
                    showingAgeAlert = true
                } label: {
                    ScalableIcon(systemName: "pencil")
                }
            }
        }
    }
}

#Preview("DemoView") {
    DemoView()
}
