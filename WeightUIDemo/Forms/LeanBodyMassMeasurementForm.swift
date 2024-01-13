import SwiftUI
import PrepShared
import SwiftUIIntrospect

struct LeanBodyMassMeasurementForm: View {

    @Environment(\.dismiss) var dismiss

    @Environment(SettingsProvider.self) var settingsProvider
    @Bindable var healthProvider: HealthProvider
    
    @State var time = Date.now
    @State var source: LeanBodyMassSource = .equation
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

    let add: (LeanBodyMassMeasurement) -> ()

    init(
        healthProvider: HealthProvider,
        add: @escaping (LeanBodyMassMeasurement) -> ()
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
                .onAppear(perform: appeared)
        }
        .scrollDismissesKeyboard(.immediately)
        .interactiveDismissDisabled(dismissDisabled)
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    func appeared() {
        /// Recalculate if we pop back from an equation variable
        if source == .equation {
            calculateEquation()
            setIsDirty()
        }
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
                doubleUnitString: doubleUnitString
            )
        }
        .padding(.horizontal, BottomValueHorizontalPadding)
        .padding(.vertical, BottomValueVerticalPadding)
        .background(.bar)
    }
    
    var measurement: LeanBodyMassMeasurement? {
        guard let leanBodyMassInKg else { return nil }
        return LeanBodyMassMeasurement(
            date: time,
            leanBodyMassInKg: leanBodyMassInKg,
            fatPercentage: fatPercentageInput.double,
            source: source
        )
    }
    
    var hasMeasurement: Bool {
        measurement != nil
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add") {
                    guard let measurement else { return }
                    add(measurement)
                    dismiss()
                }
                .fontWeight(.bold)
                .disabled(!isDirty || !hasMeasurement)
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
            settingsProvider: settingsProvider,
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
            title: settingsProvider.unitString(for: .fatPercentage),
            doubleInput: $fatPercentageInput,
            hasFocused: $hasFocusedFatPercentage,
            delayFocus: true,
            footer: "The weight below will be used to calculate your Lean Body Mass.",
            handleChanges: handleFatPercentageValue
        )
    }
    
    var weightSection: some View {
        VariablesSections(
            subject: .equation,
            healthDetails: Binding<[HealthDetail]>(
                get: { [.weight] },
                set: { _ in }
            ),
            isRequired: Binding<Bool>(
                get: { self.source == .fatPercentage },
                set: { _ in }
            ),
            healthProvider: healthProvider,
            date: date,
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
        VariablesSections(
            subject: .equation,
            healthDetails: Binding<[HealthDetail]>(
                get: { equation.requiredHealthDetails },
                set: { _ in }
            ),
            healthProvider: healthProvider,
            date: date,
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
        /// Reset these immediately to make sure the text field gets focused
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
            leanBodyMassInKg = kg
            calculateFatPercentage(forLeanBodyMass: kg)
            setIsDirty()
        }
    }

    func handleFatPercentageValue() {
        withAnimation {
            calculateLeanBodyMass(forFatPercentage: fatPercentageInput.double)
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
    
    var currentOrLatestWeightInKg: Double? {
        healthProvider.currentOrLatestWeightInKg
    }
    
    func calculateEquation() {
        let heightInCm = healthProvider.currentOrLatestHeightInCm
        let biologicalSex = healthProvider.biologicalSex
        
        let leanBodyMassInKg: Double? = equation.calculateInKg(
            biologicalSex: biologicalSex,
            weightInKg: currentOrLatestWeightInKg,
            heightInCm: heightInCm
        )
        
        withAnimation {
            setLeanBodyMassInKg(leanBodyMassInKg)
            calculateFatPercentage()
        }
    }
    
    func calculateFatPercentage(forLeanBodyMass leanBodyMassInKg: Double? = nil) {
        guard let leanBodyMassInKg = leanBodyMassInKg ?? self.leanBodyMassInKg,
            let currentOrLatestWeightInKg
        else {
            setFatPercentage(nil)
            return
        }
        let weight = currentOrLatestWeightInKg
        let p = ((max(0, (weight - leanBodyMassInKg)) / weight) * 100)
        setFatPercentage(p.rounded(toPlaces: 1))
    }
    
    func calculateLeanBodyMass(forFatPercentage p: Double? = nil) {
        guard let p = p ?? self.fatPercentageInput.double,
              let currentOrLatestWeightInKg
        else {
            setLeanBodyMassInKg(nil)
            return
        }
        let weight = currentOrLatestWeightInKg
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

#Preview("DemoView") {
    DemoView()
}
