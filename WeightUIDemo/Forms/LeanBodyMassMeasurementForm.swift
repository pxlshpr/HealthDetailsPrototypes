import SwiftUI
import PrepShared
import SwiftUIIntrospect


//TODO: Next
/// [ ] Make CustomSection its own View, passing in the bool for tracking whether its been focused (so we can reset it here). Have it usable for Height or Weight (check MeasurementForm) and use it in both places
/// [ ] Now use a single value field for percentage (which we should extract out of CustomSection and make it another view thats used there for the single unit values)
/// [ ] Now visit the LBM calculation and make sure its happening
/// [ ] See if we can get rid of `value` and just use `doubleInput` and `intInput` which we set whenever calculated (through fat percentage and equation) so that the value is always consistent amongst the sections (we don't need to *remember* what values each section had
/// [ ] Now do the date stuff for fetching the weight. Consider how we want to save it—check Reminders for where we had a reminder about this first.
/// [ ] Test by saving height for past date, and weight for today, then making sure equation variables correctly picks up the values from the backend (we'll need HealthProvider to help us with this somehow, even though its for a past date)
struct LeanBodyMassMeasurementForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    @Environment(\.dismiss) var dismiss
    
    @Bindable var healthProvider: HealthProvider
    
    @State var time = Date.now

    @State var source: LeanBodyMassSource = .fatPercentage
    @State var equation: LeanBodyMassEquation = .boer
    
    @State var value: Double? = 72.0
    
    @State var doubleInput = DoubleInput(automaticallySubmitsValues: true)
    @State var intInput = IntInput(automaticallySubmitsValues: true)

    @State var fatPercentageInput = DoubleInput(double: 24.8)
    
    @State var isDirty: Bool = false
    @State var dismissDisabled: Bool = false

//    @State var showingAlert = false
//    @State var showingFatPercentageAlert = false
    @State var showingEquationsInfo = false

    let add: (Int, Double, Date) -> ()

    init(
        healthProvider: HealthProvider,
        add: @escaping (Int, Double, Date) -> ()
    ) {
        self.healthProvider = healthProvider
        self.add = add
    }
    
    var body: some View {
        NavigationView {
            form
                .navigationTitle("Lean Body Mass")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .safeAreaInset(edge: .bottom) { bottomValue }
        }
        .scrollDismissesKeyboard(.immediately)
//        .alert("Enter your Lean Body Mass", isPresented: $showingAlert) {
//            TextField("kg", text: customInput.binding)
//                .keyboardType(.decimalPad)
//            Button("OK", action: submitCustomValue)
//            Button("Cancel") {
//                customInput.cancel()
//            }
//        }
//        .alert("Enter your Fat Percentage", isPresented: $showingFatPercentageAlert) {
//            TextField("%", text: fatPercentageInput.binding)
//                .keyboardType(.decimalPad)
//            Button("OK", action: submitFatPercentage)
//            Button("Cancel") { 
//                fatPercentageInput.cancel()
//            }
//        }
        .interactiveDismissDisabled(dismissDisabled)
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    var form: some View {
        Form {
            dateTimeSection
            sourceSection
            switch source {
            case .equation:
                equationSection
                equationVariablesSections
            case .fatPercentage:
                fatPercentageEnterSection
                weightSection
            case .userEntered:
                customSection
                weightSection
            default:
                EmptyView()
            }
        }
    }
    
    var bottomValue: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            if let fatPercentage = fatPercentageInput.double {
                Text("\(fatPercentage.roundedToOnePlace)")
                    .contentTransition(.numericText(value: fatPercentage))
                    .font(LargeNumberFont)
                    .foregroundStyle(.primary)
                Text("% fat")
                    .font(LargeUnitFont)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let value {
                Text("\(value.roundedToOnePlace)")
                    .contentTransition(.numericText(value: value))
                    .font(LargeNumberFont)
                    .foregroundStyle(.primary)
                Text("kg")
                    .font(LargeUnitFont)
                    .foregroundStyle(.secondary)
            } else {
                ZStack {
                    
                    /// dummy text placed to ensure height stays consistent
                    Text("0")
                        .font(LargeNumberFont)
                        .opacity(0)

                    Text("Not Set")
                        .font(LargeUnitFont)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, BottomValueHorizontalPadding)
        .padding(.vertical, BottomValueVerticalPadding)
        .background(.bar)
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add") {
                    dismiss()
                }
                .fontWeight(.bold)
                .disabled(!isDirty)
            }
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    @State var hasFocusedCustom: Bool = false

    var customSection: some View {

        func introspect(_ textField: UITextField) {
            guard !hasFocusedCustom else { return }
            textField.becomeFirstResponder()
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
            hasFocusedCustom = true
        }
        
        func dualUnit(_ secondUnitString: String) -> some View {
            let firstComponent = Binding<String>(
                get: { intInput.binding.wrappedValue },
                set: { newValue in
                    intInput.binding.wrappedValue = newValue
                    setIsDirty()
                }
            )
            
            let secondComponent = Binding<String>(
                get: { doubleInput.binding.wrappedValue },
                set: { newValue in
                    doubleInput.binding.wrappedValue = newValue
                    guard let double = doubleInput.double else {
                        handleCustomValue()
                        return
                    }
                    
                    if double >= BodyMassUnit.upperSecondaryUnitValue {
                        doubleInput.binding.wrappedValue = ""
                    }
                    handleCustomValue()
                }
            )
            return Group {
                HStack {
                    Text(unitString)
                    Spacer()
                    TextField("", text: firstComponent)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .introspect(.textField, on: .iOS(.v17)) { introspect($0) }
                }
                HStack {
                    Text(secondUnitString)
                    Spacer()
                    TextField("", text: secondComponent)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        
        var singleUnit: some View {
            let firstComponent = Binding<String>(
                get: { doubleInput.binding.wrappedValue },
                set: { newValue in
                    doubleInput.binding.wrappedValue = newValue
                    handleCustomValue()
                }
            )

            return HStack {
                Text(unitString)
                Spacer()
                TextField("", text: firstComponent)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .introspect(.textField, on: .iOS(.v17)) { introspect($0) }
            }
        }
        return Section {
            if let secondUnitString {
                dualUnit(secondUnitString)
            } else {
                singleUnit
            }
        }
    }
    
    var unitString: String {
        settingsProvider.bodyMassUnit.abbreviation
    }

    var secondUnitString: String? {
        settingsProvider.bodyMassUnit.secondaryUnit
    }
    
    var customSection_: some View {
        EmptyView()
//        InputSection(
//            name: "Lean Body Mass",
//            valueString: Binding<String?>(
//                get: { customInput.double?.clean },
//                set: { _ in }
//            ),
//            showingAlert: $showingAlert,
//            unitString: "kg",
//            footerString: "The weight below will be used to calculate your Fat Percentage."
//        )
    }
    
    var fatPercentageEnterSection: some View {
        EmptyView()
//        InputSection(
//            name: "Fat Percentage",
//            valueString: Binding<String?>(
//                get: { fatPercentageInput.double?.clean },
//                set: { _ in }
//            ),
//            showingAlert: $showingFatPercentageAlert,
//            unitString: "%",
//            footerString: "The weight below will be used to calculate your Lean Body Mass."
//        )
    }
    
    var weightSection: some View {
        EquationVariablesSections(
            healthDetails: Binding<[HealthDetail]>(
                get: { [.weight] },
                set: { _ in }
            ),
            healthProvider: healthProvider,
            pastDate: date,
            isEditing: .constant(false),
            isPresented: Binding<Bool>(
                get: { true },
                set: { newValue in
                    if !newValue {
                        dismiss()
                    }
                }
            ),
            dismissDisabled: $dismissDisabled,
            showHeader: false
        )
    }

    var equationVariablesSections: some View {
        EquationVariablesSections(
            healthDetails: Binding<[HealthDetail]>(
                get: { equation.requiredHealthDetails },
                set: { _ in }
            ),
            healthProvider: healthProvider,
            pastDate: date,
            isEditing: .constant(false),
            isPresented: Binding<Bool>(
                get: { true },
                set: { newValue in
                    if !newValue {
                        dismiss()
                    }
                }
            ),
            dismissDisabled: $dismissDisabled
        )
    }
    
    var equationSection: some View {
        let binding = Binding<LeanBodyMassEquation>(
            get: { equation },
            set: { newValue in
                withAnimation {
                    equation = newValue
                    calculateEquation()
                    setIsDirty()
                }
            }
        )
        
        var footer: some View {
            Button {
                showingEquationsInfo = true
            } label: {
                Text("Learn more…")
                    .font(.footnote)
            }
        }
        
        return Section(footer: footer) {
            Picker("Equation", selection: binding) {
                ForEach(LeanBodyMassEquation.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    var dateTimeSection: some View {
        Section {
            DatePicker(
                "Date",
                selection: .constant(date),
                displayedComponents: .date
            )
            .disabled(true)
            DatePicker(
                "Time",
                selection: $time,
                displayedComponents: .hourAndMinute
            )
        }
    }
    
    var sourceSection: some View {
        let binding = Binding<LeanBodyMassSource>(
            get: { source },
            set: { newValue in
                withAnimation {
                    source = newValue
//                    calculateEquation()
                    setIsDirty()
                }
                switch source {
                case .userEntered:
                    break
//                    showingAlert = true
                case .fatPercentage:
                    hasFocusedCustom = false
                    break
//                    showingFatPercentageAlert = true
                case .equation:
                    hasFocusedCustom = false
                    calculateEquation()
                default:
                    break
                }
            }
        )
        var picker: some View {
            Picker("Source", selection: binding) {
                ForEach(LeanBodyMassSource.formCases, id: \.self) { source in
                    Text(source.name).tag(source)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
        }
        
        var description: String {
            switch source {
            case .healthKit:
                ""
            case .equation:
                "Use an equation to calculate your Lean Body Mass."
            case .fatPercentage:
                "Use your fat percentage to calculate your Lean Body Mass."
            case .userEntered:
                "Enter your Lean Body Mass manually."
            }
        }
        return Section {
            picker
            Text(description)
        }
    }
    
    //MARK: - Actions
    
    func setDismissDisabled() {
        dismissDisabled = isDirty
    }
    
    func handleCustomValue() {
        withAnimation {
            let value = doubleInput.double
            self.value = value
            calculateFatPercentage(forLeanBodyMass: value)
            setIsDirty()
        }
    }
    
//    func submitCustomValue() {
//        withAnimation {
//            customInput.submitValue()
//            value = customInput.double
//            calculateFatPercentage(forLeanBodyMass: customInput.double)
//            setIsDirty()
//        }
//    }
//
//    func submitFatPercentage() {
//        withAnimation {
//            fatPercentageInput.submitValue()
//            calculateLeanBodyMass(forFatPercentage: fatPercentageInput.double)
//            setIsDirty()
//        }
//    }
    
    func calculateEquation() {
        let weightInKg: Double? = 95.7
//        let heightInCm: Double? = 177
        let heightInCm: Double? = nil
        let sexIsFemale: Bool? = false
        
        let lbm: Double? = if let weightInKg, let heightInCm, let sexIsFemale {
            equation.calculateInKg(
                sexIsFemale: sexIsFemale,
                weightInKg: weightInKg,
                heightInCm: heightInCm
            )
        } else {
            nil
        }
        withAnimation {
            setLeanBodyMass(lbm)
            calculateFatPercentage()
        }
    }
    
    func calculateFatPercentage(forLeanBodyMass lbm: Double? = nil) {
        guard let lbm = lbm ?? self.value else {
            setFatPercentage(nil)
            return
        }
        let weight = 95.7
        let p = ((max(0, (weight - lbm)) / weight) * 100)
        setFatPercentage(p)
    }
    
    func calculateLeanBodyMass(forFatPercentage p: Double? = nil) {
        guard let p = p ?? self.fatPercentageInput.double else {
            setLeanBodyMass(nil)
            return
        }
        let weight = 95.7
        let lbm = weight - ((p / 100.0) * weight)
        setLeanBodyMass(lbm)
    }
    
    func setFatPercentage(_ p: Double?) {
        guard let p = p?.rounded(toPlaces: 1) else {
            fatPercentageInput = DoubleInput()
            return
        }
        fatPercentageInput = DoubleInput(double: p)
    }
    
    func setLeanBodyMass(_ lbm: Double?) {
        guard let lbm = lbm?.rounded(toPlaces: 1) else {
            value = nil
//            customInput = DoubleInput()
            return
        }
        value = lbm
//        customInput = DoubleInput(double: lbm)
    }

    func setIsDirty() {
        isDirty = if let value {
            value != 72
            || fatPercentageInput.double != 24.8
        } else {
            false
        }
    }
    
    //MARK: - Convenience
    
    var date: Date {
        healthProvider.healthDetails.date
    }
}

#Preview("Current (kg)") {
    LeanBodyMassMeasurementForm(
        healthProvider: MockCurrentProvider
    ) { int, double, time in
        
    }
    .environment(SettingsProvider(settings: .init(bodyMassUnit: .kg)))
}

#Preview("Current (st)") {
    LeanBodyMassMeasurementForm(
        healthProvider: MockCurrentProvider
    ) { int, double, time in
        
    }
    .environment(SettingsProvider(settings: .init(bodyMassUnit: .st)))
}

#Preview("LeanBodyMassForm (kg)") {
    NavigationView {
        LeanBodyMassForm(healthProvider: MockCurrentProvider)
            .environment(SettingsProvider(settings: .init(bodyMassUnit: .kg)))
    }
}

#Preview("LeanBodyMassForm (st)") {
    NavigationView {
        LeanBodyMassForm(healthProvider: MockCurrentProvider)
            .environment(SettingsProvider(settings: .init(bodyMassUnit: .st)))
    }
}
