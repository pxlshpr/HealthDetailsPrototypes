import SwiftUI
import PrepShared

struct RestingEnergyForm: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase

    @Bindable var settingsProvider: SettingsProvider
    @Bindable var healthProvider: HealthProvider
    
    let date: Date
    let initialRestingEnergy: HealthDetails.Maintenance.Estimate.RestingEnergy

    @State var restingEnergyInKcal: Double?
    @State var source: RestingEnergySource = .healthKit
    @State var equation: RestingEnergyEquation = .katchMcardle
    @State var intervalType: HealthIntervalType = .average
    @State var interval: HealthInterval = .init(3, .day)
    @State var applyCorrection: Bool = true
    @State var correctionType: CorrectionType = .divide
    @State var correctionInput = DoubleInput(automaticallySubmitsValues: true)
    @State var customInput = DoubleInput(automaticallySubmitsValues: true)

    @State var equationValuesInKcal: [RestingEnergyEquation: Double] = [:]
    @State var hasFetchedHealthKitValues: Bool = false
    @State var healthKitAverageValuesInKcal: [HealthInterval: Double] = [:]
    @State var healthKitSameDayValueInKcal: Double? = nil
    @State var healthKitPreviousDayValueInKcal: Double? = nil
    @State var handleChangesTask: Task<Void, Error>? = nil

    @State var showingEquationsInfo = false
    @State var showingRestingEnergyInfo = false
    @State var hasFocusedCustomField = false
    @State var hasAppeared = false

    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    let saveHandler: (HealthDetails.Maintenance.Estimate.RestingEnergy) -> ()

    init(
        date: Date,
        restingEnergy: HealthDetails.Maintenance.Estimate.RestingEnergy,
        settingsProvider: SettingsProvider,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false),
        save: @escaping (HealthDetails.Maintenance.Estimate.RestingEnergy) -> ()
    ) {
        self.date = date
        self.initialRestingEnergy = restingEnergy
        self.healthProvider = healthProvider
        self.settingsProvider = settingsProvider
        self.saveHandler = save
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: date.isToday)

        let restingEnergy = healthProvider.healthDetails.maintenance.estimate.restingEnergy
        _restingEnergyInKcal = State(initialValue: restingEnergy.kcal)
        _customInput = State(initialValue: DoubleInput(
            double: restingEnergy.kcal.convertEnergy(
                from: .kcal,
                to: settingsProvider.energyUnit
            ),
            automaticallySubmitsValues: true
        ))

        _source = State(initialValue: restingEnergy.source)
        _equation = State(initialValue: restingEnergy.equation)
        _intervalType = State(initialValue: restingEnergy.healthKitSyncSettings.intervalType)
        _interval = State(initialValue: restingEnergy.healthKitSyncSettings.interval)
   
        if let correction = restingEnergy.healthKitSyncSettings.correctionValue {
            _applyCorrection = State(initialValue: true)
            _correctionType = State(initialValue: correction.type)
            
            let correctionDouble = switch correction.type {
            case .add, .subtract:
                correction.double.convertEnergy(
                    from: .kcal,
                    to: settingsProvider.energyUnit
                )
            case .multiply, .divide:
                correction.double
            }
            _correctionInput = State(initialValue: DoubleInput(
                double: correctionDouble,
                automaticallySubmitsValues: true
            ))
        } else {
            _applyCorrection = State(initialValue: false)
        }
    }
    
    init(
        settingsProvider: SettingsProvider,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            restingEnergy: healthProvider.healthDetails.maintenance.estimate.restingEnergy,
            settingsProvider: settingsProvider,
            healthProvider: healthProvider,
            isPresented: isPresented,
            dismissDisabled: dismissDisabled,
            save: healthProvider.saveRestingEnergy
        )
    }
    
    func appeared() {
        if isEditing {
            if !hasAppeared {
                Task {
                    try await fetchHealthKitValues()
                }
            }

            /// Triggers equations to re-calculate or HealthKit to resync when we pop back from an equation variable. Delay this if not the first appearance so that we get to see the animation of the value changing.
            DispatchQueue.main.asyncAfter(deadline: .now() + (hasAppeared ? 0.3 : 0)) {
                handleChanges()
            }
        }
    }

    var body: some View {
        Form {
            notice
            explanation
            sourceSection
            switch source {
            case .userEntered:
                customSection
            case .equation:
                equationSection
                variablesSections
            case .healthKit:
                healthSections
            }
        }
        .navigationTitle("Resting Energy")
        .toolbar { toolbarContent }
        .onAppear(perform: appeared)
        .onChange(of: scenePhase, scenePhaseChanged)
        .sheet(isPresented: $showingEquationsInfo) { equationExplanations }
        .sheet(isPresented: $showingRestingEnergyInfo) {
            RestingEnergyInfo()
        }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isLegacy && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
        .scrollDismissesKeyboard(.interactively)
    }
    
    func scenePhaseChanged(old: ScenePhase, new: ScenePhase) {
        switch new {
        case .active:
            Task {
                try await fetchHealthKitValues()
            }
        default:
            break
        }
    }
    
    func setDismissDisabled() {
        dismissDisabled = isLegacy && isEditing && isDirty
    }
    
    var energyUnit: EnergyUnit { settingsProvider.energyUnit }

    var bottomValue: some View {
        var double: Double? {
            restingEnergyInKcal?.convertEnergy(from: .kcal, to: energyUnit)
        }
        return MeasurementBottomBar(
            double: Binding<Double?>(
                get: { double },
                set: { _ in }
            ),
            doubleString: Binding<String?>(
                get: { double?.formattedEnergy },
                set: { _ in }
            ),
            doubleUnitString: energyUnit.abbreviation,
            isDisabled: Binding<Bool>(
                get: { !isEditing },
                set: { _ in }
            )
        )
    }
    
    var toolbarContent: some ToolbarContent {
        topToolbarContent(
            isEditing: $isEditing,
            isDirty: $isDirty,
            isPast: isLegacy,
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
            pastDate: date,
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
        .environment(settingsProvider)
    }

    @ViewBuilder
    var notice: some View {
        if isLegacy {
            NoticeSection.legacy(date, isEditing: $isEditing)
        }
    }
    
    var correctionValueInKcalIfEnergy: Double? {
        guard let double = correctionInput.double else { return nil }

        return switch correctionType {
        case .add, .subtract:       double.convertEnergy(from: energyUnit, to: .kcal)
        case .multiply, .divide:    double
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
                correctionValue: CorrectionValue(
                    type: correctionType,
                    double: correctionValueInKcalIfEnergy
                )
            )
        )
    }
    
    func handleChanges() {
        handleChangesTask?.cancel()
        handleChangesTask = Task {
            
            /// Equation Values
            if source == .equation {
                try await calculateEquationValues()
                try Task.checkCancellation()
                await MainActor.run {
                    setEquationValue()
                }
                try Task.checkCancellation()
            }
            
            /// HealthKit Values
            if source == .healthKit {
                if !hasFetchedHealthKitValues {
                    try await fetchHealthKitValues()
                }
                await MainActor.run {
                    setHealthKitValue()
                }
            }

            await MainActor.run {
                setIsDirty()
                if !isLegacy {
                    save()
                }
            }
        }
    }
    
    func calculateEquationValues() async throws {
        var dict: [RestingEnergyEquation: Double] = [:]
        for equation in RestingEnergyEquation.allCases {
            let kcal = await healthProvider.calculateRestingEnergy(
                using: equation,
                energyUnit: .kcal
            )
            dict[equation] = kcal
        }
        await MainActor.run { [dict] in
            withAnimation {
                equationValuesInKcal = dict
            }
        }
    }
    
    func fetchHealthKitValues() async throws {
//        guard !isPreview else { return }
        
        let dict = try await withThrowingTaskGroup(
            of: (HealthInterval, Double?).self,
            returning: [HealthInterval: Double].self
        ) { taskGroup in
            
            for interval in HealthInterval.healthKitEnergyIntervals {
                taskGroup.addTask {
                    let kcal = try await HealthStore.restingEnergy(
                        for: interval,
                        on: date,
                        in: .kcal
                    )
                    return (interval, kcal)
                }
            }

            var dict = [HealthInterval : Double]()

            while let tuple = try await taskGroup.next() {
                dict[tuple.0] = tuple.1
            }
            
            return dict
        }
        
        let sameDayValue = try await HealthStore.restingEnergy(on: date, in: .kcal)
        let previousDayValue = try await HealthStore.restingEnergy(on: date.moveDayBy(-1), in: .kcal)

        await MainActor.run { [dict, sameDayValue, previousDayValue] in
            withAnimation {
                healthKitAverageValuesInKcal = dict
                healthKitSameDayValueInKcal = sameDayValue
                    .rounded(.towardZero) /// Use Health App's rounding (towards zero)
                healthKitPreviousDayValueInKcal = previousDayValue
                    .rounded(.towardZero) /// Use Health App's rounding (towards zero)
            }
            if source == .healthKit {
                setHealthKitValue()
            }
            hasFetchedHealthKitValues = true
        }
    }
    
    func setHealthKitValue() {
        var value = switch intervalType {
        case .average:      healthKitAverageValuesInKcal[interval]
        case .sameDay:      healthKitSameDayValueInKcal
        case .previousDay:  healthKitPreviousDayValueInKcal
        }
        
        if applyCorrection, let correction = correctionValueInKcalIfEnergy, let v = value {
            value = switch correctionType {
            case .add:      v + correction
            case .subtract: max(v - correction, 0)
            case .multiply: v * correction
            case .divide:   correction == 0 ? nil : v / correction
            }
        }
        withAnimation {
            restingEnergyInKcal = value == 0 ? nil : value
        }
        setCustomInput()
    }
    
    func setEquationValue() {
        withAnimation {
            restingEnergyInKcal = equationValuesInKcal[equation]
        }
        setCustomInput()
    }
    
    func setCustomInput() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            customInput.setDouble(
                restingEnergyInKcal?.convertEnergy(from: .kcal, to: energyUnit)
                    .rounded(.towardZero)
            )
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
            pastDate: date,
            isEditing: $isEditing,
            applyCorrection: $applyCorrection,
            correctionType: $correctionType,
            correctionInput: $correctionInput,
            handleChanges: handleChanges,
            isRestingEnergy: true,
            restingEnergyInKcal: $restingEnergyInKcal
        )
        .environment(settingsProvider)
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
            guard source == .userEntered else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let kcal = customInput.double?.convertEnergy(from: energyUnit, to: .kcal)
                withAnimation {
                    restingEnergyInKcal = kcal
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    handleChanges()
                }
            }
        }
        
        return SingleUnitMeasurementTextField(
            title: settingsProvider.unitString(for: .energy),
            doubleInput: $customInput,
            hasFocused: $hasFocusedCustomField,
            delayFocus: true,
            footer: nil,
            handleChanges: handleCustomValue
        )
    }
    
    var equationSection: some View {
        let binding = Binding<RestingEnergyEquation>(
            get: { equation },
            set: { newValue in
                withAnimation {
                    equation = newValue
                }
                handleChanges()
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
        
        func string(for equation: RestingEnergyEquation) -> String {
            var string = equation.name
            if let kcal = equationValuesInKcal[equation] {
                let value = kcal.convertEnergy(from: .kcal, to: energyUnit)
                string += " • \(value.formattedEnergy) \(energyUnit.abbreviation)"
            }
            return string
        }
        
        return Section(header: Text("Equation"), footer: footer) {
            Picker("Equation", selection: binding) {
                ForEach(RestingEnergyEquation.allCases, id: \.self) {
                    Text(string(for: $0)).tag($0)
                }
            }
            .pickerStyle(.wheel)
            .disabled(isDisabled)
            .foregroundStyle(controlColor)
        }
    }

    //MARK: - Convenience

    var isDisabled: Bool {
        isLegacy && !isEditing
    }
    
    var controlColor: Color {
        isDisabled ? .secondary : .primary
    }
    
    var isLegacy: Bool {
        date.startOfDay < Date.now.startOfDay
    }
    
    //MARK: - Actions
    
    func undo() {
        restingEnergyInKcal = initialRestingEnergy.kcal
        customInput = DoubleInput(
            double: initialRestingEnergy.kcal.convertEnergy(
                from: .kcal,
                to: settingsProvider.energyUnit
            ),
            automaticallySubmitsValues: true
        )

        source = initialRestingEnergy.source
        equation = initialRestingEnergy.equation
        intervalType = initialRestingEnergy.healthKitSyncSettings.intervalType
        interval = initialRestingEnergy.healthKitSyncSettings.interval
   
        if let correction = initialRestingEnergy.healthKitSyncSettings.correctionValue {
            applyCorrection = true
            correctionType = correction.type
            
            let correctionDouble = switch correction.type {
            case .add, .subtract:
                correction.double.convertEnergy(
                    from: .kcal,
                    to: settingsProvider.energyUnit
                )
            case .multiply, .divide:
                correction.double
            }
            correctionInput = DoubleInput(
                double: correctionDouble,
                automaticallySubmitsValues: true
            )
        } else {
            applyCorrection = false
        }
    }
    
    func setIsDirty() {
        isDirty = restingEnergy != initialRestingEnergy
    }
    
    func save() {
        saveHandler(restingEnergy)
    }
}

//MARK: - Previews

#Preview("Current") {
    NavigationView {
        RestingEnergyForm(
            settingsProvider: SettingsProvider(),
            healthProvider: MockCurrentProvider
        )
    }
}

#Preview("Past") {
    NavigationView {
        RestingEnergyForm(
            settingsProvider: SettingsProvider(),
            healthProvider: MockPastProvider
        )
    }
}

#Preview("Demo") {
    DemoView()
}
