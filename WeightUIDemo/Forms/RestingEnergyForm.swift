import SwiftUI
import PrepShared

struct RestingEnergyForm: View {

    @Environment(\.scenePhase) var scenePhase

    @Bindable var healthProvider: HealthProvider
    @Binding var isPresented: Bool
    
    let date: Date

    @State var restingEnergyInKcal: Double?
    @State var source: RestingEnergySource
    @State var equation: RestingEnergyEquation
    @State var preferLeanBodyMass: Bool
    @State var intervalType: HealthIntervalType
    @State var interval: HealthInterval
    @State var applyCorrection: Bool
    @State var correctionType: CorrectionType = .divide
    @State var correctionInput = DoubleInput(automaticallySubmitsValues: true)
    @State var manualInput: DoubleInput

    @State var equationValuesInKcal: [RestingEnergyEquation: Double] = [:]
    @State var hasFetchedHealthKitValues: Bool = false
    @State var healthKitAverageValuesInKcal: [HealthInterval: Double] = [:]
    @State var healthKitSameDayValueInKcal: Double? = nil
    @State var healthKitPreviousDayValueInKcal: Double? = nil
    @State var handleChangesTask: Task<Void, Error>? = nil

    @State var showingEquationsInfo = false
    @State var showingRestingEnergyInfo = false
    @State var hasFocusedCustomField: Bool = true
    @State var hasAppeared = false

    let saveHandler: (HealthDetails.Maintenance.Estimate.RestingEnergy, Bool) -> ()

    init(
        date: Date,
        restingEnergy: HealthDetails.Maintenance.Estimate.RestingEnergy,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        saveHandler: @escaping (HealthDetails.Maintenance.Estimate.RestingEnergy, Bool) -> ()
    ) {
        self.date = date
        self.healthProvider = healthProvider
        self.saveHandler = saveHandler
        _isPresented = isPresented

        _restingEnergyInKcal = State(initialValue: restingEnergy.kcal)
        _manualInput = State(initialValue: DoubleInput(
            double: restingEnergy.kcal.convertEnergy(
                from: .kcal,
                to: healthProvider.settingsProvider.energyUnit
            ),
            automaticallySubmitsValues: true
        ))

        _source = State(initialValue: restingEnergy.source)
        _equation = State(initialValue: restingEnergy.equation ?? .default)
        _preferLeanBodyMass = State(initialValue: restingEnergy.preferLeanBodyMass)
        
        let healthKitFetchSettings = restingEnergy.healthKitFetchSettings ?? HealthKitFetchSettings()
        _intervalType = State(initialValue: healthKitFetchSettings.intervalType)
        _interval = State(initialValue: healthKitFetchSettings.interval)
   
        if let correction = healthKitFetchSettings.correction {
            _applyCorrection = State(initialValue: true)
            _correctionType = State(initialValue: correction.type)
            
            let correctionDouble = switch correction.type {
            case .add, .subtract:
                correction.value.convertEnergy(
                    from: .kcal,
                    to: healthProvider.settingsProvider.energyUnit
                )
            case .multiply, .divide:
                correction.value
            }
            _correctionInput = State(initialValue: DoubleInput(
                double: correctionDouble,
                automaticallySubmitsValues: true
            ))
        } else {
            _applyCorrection = State(initialValue: false)
        }
    }
    
    var body: some View {
        Form {
            dateSection
            explanation
            sourceSection
            switch source {
            case .manual:
                manualSection
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
        .sheet(isPresented: $showingEquationsInfo) { RestingEnergyEquationsInfo() }
        .sheet(isPresented: $showingRestingEnergyInfo) { RestingEnergyInfo() }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .scrollDismissesKeyboard(.interactively)
    }
    
    func appeared() {
        if !hasAppeared {
            Task {
                await calculateEquationValues()
                await fetchHealthKitValues()
            }
            hasAppeared = true
        }

        /// Triggers equations to re-calculate or HealthKit to resync when we pop back from an equation variable. Delay this if not the first appearance so that we get to see the animation of the value changing.
        DispatchQueue.main.asyncAfter(deadline: .now() + (hasAppeared ? 0.3 : 0)) {
            handleChanges()
        }
    }

    func scenePhaseChanged(old: ScenePhase, new: ScenePhase) {
        switch new {
        case .active:
            Task {
                await fetchHealthKitValues()
            }
        default:
            break
        }
    }
    
    var energyUnit: EnergyUnit { healthProvider.settingsProvider.energyUnit }

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
            doubleUnitString: energyUnit.abbreviation
        )
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
    
    //MARK: - Sections

    var variablesSections: some View {
        VariablesSections(
            type: .equation,
            variables: Binding<Variables>(
                get: { equation.variables },
                set: { _ in }
            ),
            preferLeanBodyMass: Binding<Bool>(
                get: { preferLeanBodyMass },
                set: { newValue in
                    preferLeanBodyMass = newValue
                    handleChanges()
                }
            ),
            healthProvider: healthProvider,
            date: date,
            isPresented: Binding<Bool>(
                get: { true },
                set: { newValue in
                    if !newValue {
                        isPresented = false
                    }
                }
            )
        )
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

    var correctionValueInKcalIfEnergy: Double? {
        guard let double = correctionInput.double else { return nil }

        return switch correctionType {
        case .add, .subtract:       double.convertEnergy(from: energyUnit, to: .kcal)
        case .multiply, .divide:    double
        }
    }
    
    var restingEnergy: HealthDetails.Maintenance.Estimate.RestingEnergy {
        var healthKitFetchSettings: HealthKitFetchSettings {
            var correction: HealthKitFetchSettings.Correction? {
                guard let correctionValueInKcalIfEnergy else { return nil }
                return HealthKitFetchSettings.Correction(
                    type: correctionType,
                    value: correctionValueInKcalIfEnergy
                )
            }

            return .init(
                intervalType: intervalType,
                interval: interval,
                correction: correction
            )
        }
        
        return .init(
            kcal: restingEnergyInKcal,
            source: source,
            equation: source == .equation ? equation : nil,
            preferLeanBodyMass: preferLeanBodyMass,
            healthKitFetchSettings: source == .healthKit ? healthKitFetchSettings : nil
        )
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
            
            /// HealthKit Values
            if source == .healthKit {
                if hasFetchedHealthKitValues {
                    await MainActor.run {
                        setHealthKitValue()
                    }
                } else {
                    await fetchHealthKitValues()
                }
                try Task.checkCancellation()
            }

            await MainActor.run {
                save()
            }
        }
    }
    
    func calculateEquationValues() async {
        
        healthProvider.healthDetails.maintenance.estimate.restingEnergy.preferLeanBodyMass = preferLeanBodyMass
        
        var dict: [RestingEnergyEquation: Double] = [:]
        for equation in RestingEnergyEquation.allCases {
            let kcal = await healthProvider.calculateRestingEnergyInKcal(using: equation)
            dict[equation] = kcal
        }
        await MainActor.run { [dict] in
            withAnimation {
                equationValuesInKcal = dict
            }
        }
    }
    
    func fetchHealthKitValues() async {
        
        let dict = await withTaskGroup(
            of: (HealthInterval, Double?).self,
            returning: [HealthInterval: Double].self
        ) { taskGroup in
            
            for interval in HealthInterval.healthKitEnergyIntervals {
                taskGroup.addTask {
                    let kcal = await HealthStore.energy(
                        .resting,
                        for: interval,
                        on: date,
                        in: .kcal
                    )
                    return (interval, kcal)
                }
            }

            var dict = [HealthInterval : Double]()

            while let tuple = await taskGroup.next() {
                dict[tuple.0] = tuple.1
            }
            
            return dict
        }
        
        let sameDayValue = await HealthStore.energy(.resting, on: date, in: .kcal)
        let previousDayValue = await HealthStore.energy(.resting, on: date.moveDayBy(-1), in: .kcal)

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
        
        if applyCorrection, 
            let correction = correctionValueInKcalIfEnergy,
            let v = value
        {
            value = switch correctionType {
            case .add:      v + correction
            case .subtract: max(v - correction, 0)
            case .multiply: correction > 0 ? v * correction : v
            case .divide:   correction > 0 ? v / correction : v
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
            manualInput.setDouble(
                restingEnergyInKcal?
                    .convertEnergy(from: .kcal, to: energyUnit)
                    .rounded(.towardZero)
            )
        }
    }
    
    var sourceSection: some View {
        let binding = Binding<RestingEnergySource>(
            get: { source },
            set: { newValue in
                /// Reset this immediately to make sure the text field gets focused
                if newValue == .manual {
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
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
        }
        
        var descriptionRow: some View {
            var description: String {
                switch source {
                case .healthKit:
                    "Use the Resting Energy data recorded in the Apple Health app."
                case .equation:
                    "Use an equation to calculate your Resting Energy."
                case .manual:
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
            date: date,
            intervalType: $intervalType,
            interval: $interval,
            applyCorrection: $applyCorrection,
            correctionType: $correctionType,
            correctionInput: $correctionInput,
            handleChanges: handleChanges,
            isRestingEnergy: true,
            energyInKcal: $restingEnergyInKcal,
            energyUnitString: energyUnit.abbreviation
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
    
    var manualSection: some View {
        func handleCustomValue() {
            guard source == .manual else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let kcal = manualInput.double?.convertEnergy(from: energyUnit, to: .kcal)
                withAnimation {
                    restingEnergyInKcal = kcal
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    handleChanges()
                }
            }
        }
        
        return SingleUnitMeasurementTextField(
            title: energyUnit.abbreviation,
            doubleInput: $manualInput,
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
        
        var footer: some View {
            Button {
                showingEquationsInfo = true
            } label: {
                Text("Learn more…")
                    .font(.footnote)
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
        }
    }

    func save() {
        let shouldResync = source == .healthKit
        saveHandler(restingEnergy, shouldResync)
    }
}

#Preview("Demo") {
    DemoView()
}
