import SwiftUI
import PrepShared
import SwiftUIIntrospect

//TODO: Next
/// [ ] Now actually save weight in WeightForm from equation variables section
/// [ ] Make sure we've updated the weight in HealthDetails (either manually or by re-fetching from backend, but maybe just leave it manual since we already have the data)
/// [ ] Ensure updating it shows the correct weight in the form again
/// [ ] Make sure we've left comments for the saved weight to be persisted (and repurcussions managed) by HealthProvider
/// [ ] Test by saving height for past date, and weight for today, then making sure equation variables correctly picks up the values from the backend (we'll need HealthProvider to help us with this somehow, even though its for a past date)
struct LeanBodyMassMeasurementForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    @Environment(\.dismiss) var dismiss
    
    @Bindable var healthProvider: HealthProvider
    
    @State var time = Date.now

    @State var source: LeanBodyMassSource = .userEntered
    @State var equation: LeanBodyMassEquation = .boer
    
    @State var leanBodyMassInKg: Double?
    
    @State var doubleInput = DoubleInput(automaticallySubmitsValues: true)
    @State var intInput = IntInput(automaticallySubmitsValues: true)

    @State var fatPercentageInput = DoubleInput(automaticallySubmitsValues: true)
    
    @State var isDirty: Bool = false
    @State var dismissDisabled: Bool = false

    @State var showingEquationsInfo = false

    @State var hasFocusedCustom: Bool = false
    @State var hasFocusedFatPercentage: Bool = false

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
    
    var unit: BodyMassUnit {
        settingsProvider.bodyMassUnit
    }
    
    var bottomValue: some View {
        var intUnitString: String? {
            unit.intUnitString
        }
        
        var doubleUnitString: String {
            unit.doubleUnitString
        }
        
        var double: Double? {
            guard let leanBodyMassInKg else { return nil }
            return BodyMassUnit.kg
                .doubleComponent(leanBodyMassInKg, in: unit)
        }
        
        var int: Int? {
            guard let leanBodyMassInKg else { return nil }
            return BodyMassUnit.kg
                .intComponent(leanBodyMassInKg, in: unit)
        }

        return HStack(alignment: .firstTextBaseline, spacing: 5) {
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
            MeasurementBottomText(
                int: Binding<Int?>(
                    get: { int }, set: { _ in }
                ),
                intUnitString: intUnitString,
                double: Binding<Double?>(
                    get: { double }, set: { _ in }
                ),
                doubleString: Binding<String?>(
                    get: { double?.cleanHealth }, set: { _ in }
                ),
                doubleUnitString: doubleUnitString,
                isDisabled: .constant(false)
            )
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

    var customSection: some View {
        MeasurementInputSection(
            type: .leanBodyMass,
            doubleInput: $doubleInput,
            intInput: $intInput,
            hasFocused: $hasFocusedCustom,
            delayFocus: true,
            footer: "The weight below will be used to calculate your Fat Percentage.",
            handleChanges: handleCustomValue
        )
    }
    
    var unitString: String {
        unit.abbreviation
    }

    var secondUnitString: String? {
        unit.secondaryUnit
    }
    
    var fatPercentageEnterSection: some View {
        SingleUnitMeasurementTextField(
            type: .fatPercentage,
            doubleInput: $fatPercentageInput,
            hasFocused: $hasFocusedFatPercentage,
            delayFocus: true,
            footer: "The weight below will be used to calculate your Lean Body Mass.",
            handleChanges: handleFatPercentageValue
        )
    }
    
    var weightSection: some View {
        EquationVariablesSections(
            healthDetails: Binding<[HealthDetail]>(
                get: { [.weight] },
                set: { _ in }
            ),
            isRequired: Binding<Bool>(
                get: { self.source == .fatPercentage },
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
    
    func handleNewSource(_ newValue: LeanBodyMassSource) {
        /// Reset this immediately to make sure the text field gets focused
        if newValue == .userEntered {
            hasFocusedCustom = false
        }
        if newValue == .fatPercentage {
            hasFocusedFatPercentage = false
        }
        
        /// If we're moving away from fat percentage, round it off to 1 decimal place
        if source == .fatPercentage, newValue != .fatPercentage {
            setFatPercentage(fatPercentageInput.double?.rounded(toPlaces: 1))
        }
        
        withAnimation {
            source = newValue
            setIsDirty()
        }
        
        switch source {
        case .userEntered:
            break
        case .fatPercentage:
            break
        case .equation:
            calculateEquation()
        default:
            break
        }
    }
    
    var sourceSection: some View {
        let binding = Binding<LeanBodyMassSource>(
            get: { source },
            set: { handleNewSource($0) }
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
        let double: Double? = if unit.hasTwoComponents {
            doubleInput.double ?? 0
        } else {
            doubleInput.double
        }
        let int: Int? = if unit.hasTwoComponents {
            intInput.int
        } else {
            0
        }
        
        let kg: Double? = if let int, let double {
            unit.convert(int, double, to: .kg)
        } else {
            nil
        }
        withAnimation {
            self.leanBodyMassInKg = kg
            calculateFatPercentage(forLeanBodyMass: kg)
            setIsDirty()
        }
    }

    func handleFatPercentageValue() {
        guard let double = fatPercentageInput.double else { return }
        withAnimation {
            calculateLeanBodyMass(forFatPercentage: double)
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
        let heightInCm: Double? = 177
//        let heightInCm: Double? = nil
        let sexIsFemale: Bool? = false
        
        let leanBodyMassInKg: Double? = if let weightInKg, let heightInCm, let sexIsFemale {
            equation.calculateInKg(
                sexIsFemale: sexIsFemale,
                weightInKg: weightInKg,
                heightInCm: heightInCm
            )
        } else {
            nil
        }
        withAnimation {
            setLeanBodyMassInKg(leanBodyMassInKg)
            calculateFatPercentage()
        }
    }
    
    func calculateFatPercentage(forLeanBodyMass leanBodyMassInKg: Double? = nil) {
        guard let leanBodyMassInKg = leanBodyMassInKg ?? self.leanBodyMassInKg else {
            setFatPercentage(nil)
            return
        }
        let weight = 95.7
        let p = ((max(0, (weight - leanBodyMassInKg)) / weight) * 100)
        setFatPercentage(p.rounded(toPlaces: 1))
    }
    
    func calculateLeanBodyMass(forFatPercentage p: Double? = nil) {
        guard let p = p ?? self.fatPercentageInput.double else {
            setLeanBodyMassInKg(nil)
            return
        }
        let weight = 95.7
        let kg = weight - ((p / 100.0) * weight)
        setLeanBodyMassInKg(kg)
    }
    
    func setFatPercentage(_ p: Double?) {
        guard let p else {
            fatPercentageInput = DoubleInput(automaticallySubmitsValues: true)
            return
        }
        fatPercentageInput = DoubleInput(double: p, automaticallySubmitsValues: true)
    }
    
    func setLeanBodyMassInKg(_ leanBodyMassInKg: Double?) {
        guard let leanBodyMassInKg else {
            self.leanBodyMassInKg = nil
            doubleInput = DoubleInput(automaticallySubmitsValues: true)
            intInput = IntInput(automaticallySubmitsValues: true)
            return
        }
        
        self.leanBodyMassInKg = leanBodyMassInKg
        let double = BodyMassUnit.kg.doubleComponent(leanBodyMassInKg, in: unit).rounded(toPlaces: 1)
        doubleInput = DoubleInput(double: double, automaticallySubmitsValues: true)
        
        intInput = if let int = BodyMassUnit.kg.intComponent(leanBodyMassInKg, in: unit) {
            IntInput(int: int, automaticallySubmitsValues: true)
        } else {
            IntInput(automaticallySubmitsValues: true)
        }

    }

    func setIsDirty() {
        isDirty = leanBodyMassInKg != nil
        || fatPercentageInput.double != nil
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

#Preview("DemoView") {
    DemoView()
}
