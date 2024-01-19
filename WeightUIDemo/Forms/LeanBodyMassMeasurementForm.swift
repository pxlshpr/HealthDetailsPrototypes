import SwiftUI
import PrepShared
import SwiftUIIntrospect

struct LeanBodyMassMeasurementForm: View {

    @Environment(\.dismiss) var dismiss

    @Bindable var healthProvider: HealthProvider
    
    @State var time = Date.now
    @State var source: MeasurementSource = .equation
    @State var equation: LeanBodyMassAndFatPercentageEquation = .cunBAE
    
    @State var leanBodyMassInKg: Double?
    @State var doubleInput = DoubleInput(automaticallySubmitsValues: true)
    @State var intInput = IntInput(automaticallySubmitsValues: true)
    
    @State var isDirty: Bool = false
    @State var dismissDisabled: Bool = false

    @State var showingEquationsInfo = false
    @State var hasFocusedCustom: Bool = false

    @State var handleChangesTask: Task<Void, Error>? = nil
    @State var equationValuesInKg: [LeanBodyMassAndFatPercentageEquation: Double] = [:]
    @State var hasAppeared = false

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
        if !hasAppeared {
            Task {
                await calculateEquationValues()
            }
            hasAppeared = true
        }

        /// Triggers equations to re-calculate or HealthKit to resync when we pop back from an equation variable. Delay this if not the first appearance so that we get to see the animation of the value changing.
        DispatchQueue.main.asyncAfter(deadline: .now() + (hasAppeared ? 0.3 : 0)) {
            handleChanges()
        }
    }
    
    func handleChanges() {
        handleChangesTask?.cancel()
        handleChangesTask = Task {
            
            /// Equation Values
            if source == .equation {
                await calculateEquationValues()
                try Task.checkCancellation()
                await MainActor.run {
                    setEquationValue()
                }
                try Task.checkCancellation()
            }
            
            await MainActor.run {
                setIsDirty()
            }
        }
    }
    
    func setEquationValue() {
        withAnimation {
            leanBodyMassInKg = equationValuesInKg[equation]
        }
        setCustomInput()
    }
    
    var bodyMassUnit: BodyMassUnit {
        healthProvider.settingsProvider.bodyMassUnit
    }
    
    func setCustomInput() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let leanBodyMassInKg = leanBodyMassInKg?.rounded(toPlaces: 1)
            let double: Double? = if let leanBodyMassInKg {
                BodyMassUnit.kg.doubleComponent(leanBodyMassInKg, in: bodyMassUnit)
            } else { nil }
            let int: Int? = if let leanBodyMassInKg {
                BodyMassUnit.kg.intComponent(leanBodyMassInKg, in: bodyMassUnit)
            } else { nil }
            doubleInput.setDouble(double)
            intInput.setNewValue(int)
        }
    }

    func calculateEquationValues() async {
        var dict: [LeanBodyMassAndFatPercentageEquation: Double] = [:]
        for equation in LeanBodyMassAndFatPercentageEquation.allCases {
            let percent = await healthProvider.calculateLeanBodyMassInKg(using: equation)
            dict[equation] = percent
        }
        await MainActor.run { [dict] in
            withAnimation {
                equationValuesInKg = dict
            }
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
            case .userEntered:
                customSection
            default:
                EmptyView()
            }
        }
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

        return MeasurementBottomBar(
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
        func handleCustomValue() {
            guard source == .userEntered else { return }
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                
                withAnimation {
                    leanBodyMassInKg = kg
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    handleChanges()
                }
            }
        }
        
        return MeasurementInputSection(
            type: .leanBodyMass,
            settingsProvider: healthProvider.settingsProvider,
            doubleInput: $doubleInput,
            intInput: $intInput,
            hasFocused: $hasFocusedCustom,
            delayFocus: true,
            handleChanges: handleCustomValue
        )
    }

    var equationVariablesSections: some View {
        VariablesSections(
            type: .equation,
            variables: Binding<Variables>(
                get: { equation.variables },
                set: { _ in }
            ),
            healthProvider: healthProvider,
            date: date,
            isPresented: Binding<Bool>(
                get: { true },
                set: { newValue in
                    if !newValue {
                        dismiss()
                    }
                }
            )
        )
    }
    
    var equationSection: some View {
        let binding = Binding<LeanBodyMassAndFatPercentageEquation>(
            get: { equation },
            set: { newValue in
                withAnimation {
                    equation = newValue
                }
                handleChanges()
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
        
        func string(for equation: LeanBodyMassAndFatPercentageEquation) -> String {
            var string = equation.name
            if let kg = equationValuesInKg[equation] {
                string += " • \(kg.valueString(convertedFrom: .kg, to: bodyMassUnit))"
            }
            return string
        }

        return Section(header: Text("Equation"), footer: footer) {
            Picker("Equation", selection: binding) {
                ForEach(LeanBodyMassAndFatPercentageEquation.allCases, id: \.self) {
                    Text(string(for: $0)).tag($0)
                }
            }
            .pickerStyle(.wheel)
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
    
    func handleNewSource(_ newValue: MeasurementSource) {
        /// Reset these immediately to make sure the text field gets focused
        if newValue == .userEntered {
            hasFocusedCustom = false
        }
        
        withAnimation {
            source = newValue
        }
        handleChanges()
    }
    
    var sourceSection: some View {
        let binding = Binding<MeasurementSource>(
            get: { source },
            set: { handleNewSource($0) }
        )
        var picker: some View {
            Picker("Source", selection: binding) {
                ForEach(MeasurementSource.formCases, id: \.self) { source in
                    Text(source.name).tag(source)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
        }
        
        var description: String {
            switch source {
            case .equation:     "Use an equation to calculate your Lean Body Mass."
            case .userEntered:  "Enter your Lean Body Mass manually."
            default:            ""
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
    
    func setIsDirty() {
        isDirty = leanBodyMassInKg != nil
    }
    
    var date: Date {
        healthProvider.healthDetails.date
    }
    
    var unit: BodyMassUnit {
        healthProvider.settingsProvider.bodyMassUnit
    }
    
    
    var measurement: LeanBodyMassMeasurement? {
        guard let leanBodyMassInKg else { return nil }
        return LeanBodyMassMeasurement(
            date: time,
            leanBodyMassInKg: leanBodyMassInKg,
            source: source,
            healthKitUUID: nil,
            equation: source == .equation ? equation : nil
        )
    }
    
    var hasMeasurement: Bool {
        measurement != nil
    }
}

struct LeanBodyMassMeasurementFormPreview: View {
    @State var healthProvider: HealthProvider? = nil
    
    @ViewBuilder
    var body: some View {
        if let healthProvider {
            LeanBodyMassMeasurementForm(healthProvider: healthProvider) { measurement in
                
            }
        } else {
            Color.clear
                .task {
                    var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(Date.now)
                    healthDetails.weight = .init(
                        weightInKg: 95,
                        measurements: [.init(date: Date.now, weightInKg: 95)]
                    )
                    healthDetails.height = .init(
                        heightInCm: 177,
                        measurements: [.init(date: Date.now, heightInCm: 177)]
                    )
                    healthDetails.biologicalSex = .male
                    healthDetails.ageInYears = 36

                    let settings = await fetchSettingsFromDocuments()
                    let healthProvider = HealthProvider(
                        healthDetails: healthDetails,
                        settingsProvider: SettingsProvider(settings: settings)
                    )
                    await MainActor.run {
                        self.healthProvider = healthProvider
                    }
                }
        }
    }
}

#Preview("Form") {
    LeanBodyMassMeasurementFormPreview()
}

#Preview("DemoView") {
    DemoView()
}

