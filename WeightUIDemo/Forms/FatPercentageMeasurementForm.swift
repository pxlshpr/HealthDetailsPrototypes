import SwiftUI
import PrepShared
import SwiftUIIntrospect

struct FatPercentageMeasurementForm: View {

    @Environment(\.dismiss) var dismiss

    @Bindable var healthProvider: HealthProvider
    
    @State var time = Date.now
    @State var source: LeanBodyMassAndFatPercentageSource = .equation
    @State var equation: LeanBodyMassAndFatPercentageEquation = .boer
    
    @State var percent: Double?
    @State var customInput = DoubleInput(automaticallySubmitsValues: true)
    
    @State var isDirty: Bool = false
    @State var dismissDisabled: Bool = false

    @State var showingEquationsInfo = false
    @State var hasFocusedCustom: Bool = false

    @State var handleChangesTask: Task<Void, Error>? = nil
    @State var equationValuesInPercent: [LeanBodyMassAndFatPercentageEquation: Double] = [:]
    @State var hasAppeared = false

    let add: (FatPercentageMeasurement) -> ()

    init(
        healthProvider: HealthProvider,
        add: @escaping (FatPercentageMeasurement) -> ()
    ) {
        self.healthProvider = healthProvider
        self.add = add
    }
    
    var body: some View {
        NavigationView {
            form
                .navigationTitle("Body Fat Percentage")
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
//        if source == .equation {
//            calculateEquation()
//            setIsDirty()
//        }
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
            percent = equationValuesInPercent[equation]
        }
        setCustomInput()
    }
    
    func setCustomInput() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            customInput.setDouble(
                percent?.rounded(toPlaces: 1)
//                    .convertEnergy(from: .kcal, to: energyUnit)
//                    .rounded(.towardZero)
            )
        }
    }

    func calculateEquationValues() async {
        var dict: [LeanBodyMassAndFatPercentageEquation: Double] = [:]
        for equation in LeanBodyMassAndFatPercentageEquation.allCases {
            let percent = await healthProvider.calculateFatPercentageInPercent(using: equation)
            dict[equation] = percent
        }
        await MainActor.run { [dict] in
            withAnimation {
                equationValuesInPercent = dict
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
        MeasurementBottomBar(
            double: Binding<Double?>(
                get: { percent }, set: { _ in }
            ),
            doubleString: Binding<String?>(
                get: { percent?.cleanHealth }, set: { _ in }
            ),
            doubleUnitString: "%"
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
//            withAnimation {
//                percent = customInput.double
//                setIsDirty()
//            }
            guard source == .userEntered else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation {
                    self.percent = customInput.double
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    handleChanges()
                }
            }
        }

        return SingleUnitMeasurementTextField(
            title: "%",
            doubleInput: $customInput,
            hasFocused: $hasFocusedCustom,
            delayFocus: true,
            handleChanges: handleCustomValue
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
//                    calculateEquation()
//                    setIsDirty()
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
            if let percent = equationValuesInPercent[equation] {
                string += " • \(percent.cleanHealth) %"
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
    
    func handleNewSource(_ newValue: LeanBodyMassAndFatPercentageSource) {
        /// Reset these immediately to make sure the text field gets focused
        if newValue == .userEntered {
            hasFocusedCustom = false
        }
        
        withAnimation {
            source = newValue
//            setIsDirty()
        }
        handleChanges()
        
//        if source == .equation {
//            calculateEquation()
//        }
    }
    
    var sourceSection: some View {
        let binding = Binding<LeanBodyMassAndFatPercentageSource>(
            get: { source },
            set: { handleNewSource($0) }
        )
        var picker: some View {
            Picker("Source", selection: binding) {
                ForEach(LeanBodyMassAndFatPercentageSource.formCases, id: \.self) { source in
                    Text(source.name).tag(source)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
        }
        
        var description: String {
            switch source {
            case .equation:     "Use an equation to calculate your Fat Percentage."
            case .userEntered:  "Enter your Fat Percentage manually."
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
    
//    func calculateEquation() {
//        let heightInCm = healthProvider.healthDetails.currentOrLatestHeightInCm
//        let weightInKg = healthProvider.healthDetails.currentOrLatestWeightInKg
//        let biologicalSex = healthProvider.biologicalSex
//        let ageInYears = healthProvider.ageInYears
//        
//        let percent: Double? = equation.calculateFatPercentageInPercent(
//            biologicalSex: biologicalSex,
//            weightInKg: weightInKg,
//            heightInCm: heightInCm,
//            ageInYears: ageInYears
//        )
//        
//        withAnimation {
//            setPercent(percent)
//        }
//    }
    
//    func setPercent(_ percent: Double?) {
//        guard let percent else {
//            self.percent = nil
//            customInput = DoubleInput(automaticallySubmitsValues: true)
//            return
//        }
//        
//        self.percent = percent
//        customInput = DoubleInput(double: percent, automaticallySubmitsValues: true)
//    }

    func setIsDirty() {
        isDirty = percent != nil
    }
    
    var date: Date {
        healthProvider.healthDetails.date
    }
    
    var unit: BodyMassUnit {
        healthProvider.settingsProvider.bodyMassUnit
    }
    
    
    var measurement: FatPercentageMeasurement? {
        guard let percent else { return nil }
        return FatPercentageMeasurement(
            date: time,
            percent: percent,
            source: source
        )
    }
    
    var hasMeasurement: Bool {
        measurement != nil
    }
}

struct FatPercentageMeasurementFormPreview: View {
    @State var healthProvider: HealthProvider? = nil
    
    @ViewBuilder
    var body: some View {
        if let healthProvider {
            FatPercentageMeasurementForm(healthProvider: healthProvider) { measurement in
                
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
    FatPercentageMeasurementFormPreview()
}

#Preview("DemoView") {
    DemoView()
}

