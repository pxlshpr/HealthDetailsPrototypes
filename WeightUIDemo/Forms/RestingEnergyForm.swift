import SwiftUI

struct RestingEnergyForm: View {

    @Environment(\.dismiss) var dismiss
    
    @Bindable var healthProvider: HealthProvider
    
    @Binding var restingEnergyInKcal: Double?

    @State var source: RestingEnergySource = .equation
    @State var equation: RestingEnergyEquation = .katchMcardle
    
    @State var intervalType: HealthIntervalType = .average
    @State var interval: HealthInterval = .init(3, .day)

    @State var applyCorrection: Bool = true
    @State var correctionType: CorrectionType = .divide
    @State var correctionInput = DoubleInput(automaticallySubmitsValues: true)

    @State var customInput = DoubleInput(automaticallySubmitsValues: true)
    
//    @State var showingAlert = false
    
    @State var showingEquationsInfo = false
    @State var showingRestingEnergyInfo = false
    @State var showingCorrectionAlert = false

    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var dismissDisabled: Bool

    @State var hasFocusedCustomField = false
    
    init(
        healthProvider: HealthProvider,
        restingEnergyInKcal: Binding<Double?> = .constant(nil),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.healthProvider = healthProvider
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: healthProvider.isCurrent)

        _restingEnergyInKcal = restingEnergyInKcal
        _customInput = State(initialValue: DoubleInput(double: restingEnergyInKcal.wrappedValue, automaticallySubmitsValues: true))

        let restingEnergy = healthProvider.healthDetails.maintenance.estimate.restingEnergy
        _source = State(initialValue: restingEnergy.source)
        _equation = State(initialValue: restingEnergy.equation)
        _intervalType = State(initialValue: restingEnergy.healthKitSyncSettings.intervalType)
        _interval = State(initialValue: restingEnergy.healthKitSyncSettings.interval)
   
        if let correction = restingEnergy.healthKitSyncSettings.correction {
            _applyCorrection = State(initialValue: true)
            _correctionType = State(initialValue: correction.type)
            _correctionInput = State(initialValue: DoubleInput(double: correction.correction, automaticallySubmitsValues: true))
        } else {
            _applyCorrection = State(initialValue: false)
        }
        
        /// If the source is manual, delay focus until push transition completes
//        if restingEnergy.source == .userEntered {
//            _focusDelay = State(initialValue: restingEnergyInKcal.wrappedValue == nil ? 1.0 : 0.6)
//        }
    }
    
    var pastDate: Date? {
        healthProvider.pastDate
    }

    var body: some View {
        Form {
            notice
            explanation
            sourceSection
            switch source {
            case .userEntered:
                customSection
//                EmptyView()
            case .equation:
                equationSection
                variablesSections
            case .healthKit:
                healthSections
            }
        }
        .navigationTitle("Resting Energy")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingEquationsInfo) { equationExplanations }
        .sheet(isPresented: $showingRestingEnergyInfo) {
            RestingEnergyInfo()
        }
//        .alert("Enter your Resting Energy", isPresented: $showingAlert) {
//            TextField("kcal", text: customInput.binding)
//                .keyboardType(.decimalPad)
//            Button("OK", action: submitCustomValue)
//            Button("Cancel") { 
//                customInput.cancel()
//            }
//        }
        .alert("Enter a correction", isPresented: $showingCorrectionAlert) {
            TextField(correctionType.textFieldPlaceholder, text: correctionInput.binding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCorrection)
            Button("Cancel") { correctionInput.cancel() }
        }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isPast && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    func setDismissDisabled() {
        dismissDisabled = isPast && isEditing && isDirty
    }

    var bottomValue: some View {
        MeasurementBottomBar(
            double: $restingEnergyInKcal,
            doubleString: Binding<String?>(
                get: { restingEnergyInKcal?.formattedEnergy },
                set: { _ in }
            ),
            doubleUnitString: "kcal",
            isDisabled: Binding<Bool>(
                get: { !isEditing },
                set: { _ in }
            )
        )
    }
    
    func submitCorrection() {
        withAnimation {
            correctionInput.submitValue()
            setIsDirty()
        }
    }

    func submitCustomValue() {
        withAnimation {
            customInput.submitValue()
            restingEnergyInKcal = customInput.double
            setIsDirty()
        }
    }

    var toolbarContent: some ToolbarContent {
        topToolbarContent(
            isEditing: $isEditing,
            isDirty: $isDirty,
            isPast: isPast,
            dismissAction: { dismiss() },
            undoAction: undo,
            saveAction: save
        )
    }
    
    var equationExplanations: some View {
        RestingEnergyEquationsInfo()
    }

    //MARK: - Sections

    var variablesSections: some View {
        EquationVariablesSections(
            healthDetails: Binding<[HealthDetail]>(
                get: { equation.requiredHealthDetails },
                set: { _ in }
            ),
            healthProvider: healthProvider,
            pastDate: pastDate,
            isEditing: $isEditing,
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

    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: $isEditing)
        }
    }
    
    var restingEnergy: HealthDetails.Maintenance.Estimate.RestingEnergy {
        .init(
            kcal: restingEnergyInKcal,
            source: source,
            equation: equation,
            healthKitSyncSettings: .init(
                intervalType: intervalType,
                interval: interval,
                correction: .init(
                    type: correctionType,
                    correction: correctionInput.double
                )
            )
        )
    }
    
    func handleChanges() {
        setIsDirty()
        if !isPast {
            save()
        }
    }
    
    var sourceSection: some View {
        let binding = Binding<RestingEnergySource>(
            get: { source },
            set: { newValue in
                /// Reset this immediately to make sure the text field gets focused
                if newValue == .userEntered {
                    hasFocusedCustomField = false
                }
                withAnimation {
                    source = newValue
                }
                handleChanges()
            }
        )
        
        var pickerRow: some View {
            Picker("Resting Energy", selection: binding) {
                ForEach(RestingEnergySource.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .foregroundStyle(controlColor)
            .pickerStyle(.segmented)
            .disabled(isDisabled)
            .listRowSeparator(.hidden)
        }
        
        var descriptionRow: some View {
            var description: String {
                switch source {
                case .healthKit:
                    "Use the Resting Energy data recorded in the Apple Health app."
                case .equation:
                    "Use an equation to calculate your Resting Energy."
                case .userEntered:
                    "Enter the Resting Energy manually."
                }
            }
            
            return Text(description)
        }
        
        return Section {
            pickerRow
            descriptionRow
        }
    }
    
    var healthSections: some View {
        EnergyAppleHealthSections(
            intervalType: $intervalType,
            interval: $interval,
            pastDate: pastDate,
            isEditing: $isEditing,
            applyCorrection: $applyCorrection,
            correctionType: $correctionType,
            correctionInput: $correctionInput,
            setIsDirty: setIsDirty,
            isRestingEnergy: true,
            showingCorrectionAlert: $showingCorrectionAlert
        )
    }

    var explanation: some View {
        var header: some View {
            Text("About Resting Energy")
                .textCase(.none)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(Color(.label))
        }
        
        var footer: some View {
            Button {
                showingRestingEnergyInfo = true
            } label: {
                Text("Learn more…")
                    .font(.footnote)
            }
        }
        
        return Section {
            VStack(alignment: .leading) {
                Text("Your Resting Energy, or your Basal Metabolic Rate (BMR), is the energy your body uses each day while minimally active. You can set it in three ways.")
            }
        }
    }
    
    var customSection: some View {
        func handleCustomValue() {
            withAnimation {
                restingEnergyInKcal = customInput.double
            }
            handleChanges()
        }
        
        return SingleUnitMeasurementTextField(
            type: .energy,
            doubleInput: $customInput,
            hasFocused: $hasFocusedCustomField,
            delayFocus: true,
            footer: nil,
            handleChanges: handleCustomValue
        )
//        return MeasurementInputSection(
//            type: type,
//            doubleInput: $doubleInput,
//            intInput: $intInput,
//            hasFocused: $hasFocusedCustom,
//            handleChanges: handleCustomValue
//        )

//        InputSection(
//            name: "Resting Energy",
//            valueString: Binding<String?>(
//                get: { restingEnergyInKcal?.formattedEnergy },
//                set: { _ in }
//            ),
//            showingAlert: $showingAlert,
//            isDisabled: Binding<Bool>(
//                get: { !isEditing },
//                set: { _ in }
//            ),
//            unitString: "kcal"
//        )
    }
    
    var equationSection: some View {
        let binding = Binding<RestingEnergyEquation>(
            get: { equation },
            set: { newValue in
                withAnimation {
                    equation = newValue
                    setIsDirty()
                }
            }
        )
        
        @ViewBuilder
        var footer: some View {
            if !isDisabled {
                Button {
                    showingEquationsInfo = true
                } label: {
                    Text("Learn more…")
                        .font(.footnote)
                }
            }
        }
        
        return Section(footer: footer) {
            Picker("Equation", selection: binding) {
                ForEach(RestingEnergyEquation.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.menu)
            .disabled(isDisabled)
            .foregroundStyle(controlColor)
        }
    }

    //MARK: - Convenience

    var isDisabled: Bool {
        isPast && !isEditing
    }
    
    var controlColor: Color {
        isDisabled ? .secondary : .primary
    }
    
    var isPast: Bool {
        pastDate != nil
    }
    
    //MARK: - Actions
    
    func undo() {
        isDirty = false
        source = .equation
        equation = .mifflinStJeor
        intervalType = .average
        interval = .init(3, .day)
        applyCorrection = true
        correctionType = .divide
        correctionInput = DoubleInput(double: 2)
        restingEnergyInKcal = 2798
        customInput = DoubleInput(double: 2798)
    }
    
    func setIsDirty() {
        isDirty = source != .equation
        || equation != .mifflinStJeor
        || intervalType != .average
        || interval != .init(3, .day)
        || applyCorrection != true
        || correctionType != .divide
        || restingEnergyInKcal != 2798
        || correctionInput.double != 2
    }
    
    func save() {
        healthProvider.saveRestingEnergy(restingEnergy)
    }
}

//MARK: - Previews

#Preview("Current") {
    NavigationView {
        RestingEnergyForm(healthProvider: MockCurrentProvider)
            .environment(SettingsProvider())
    }
}

#Preview("Past") {
    NavigationView {
        RestingEnergyForm(healthProvider: MockPastProvider)
            .environment(SettingsProvider())
    }
}

#Preview("Demo") {
    DemoView()
}
