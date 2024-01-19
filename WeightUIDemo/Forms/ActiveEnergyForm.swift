import SwiftUI
import PrepShared

struct ActiveEnergyForm: View {

    @Environment(\.scenePhase) var scenePhase

    @Bindable var healthProvider: HealthProvider
    @Binding var isPresented: Bool

    let date: Date
    let restingEnergyInKcal: Double?

    @State var activeEnergyInKcal: Double?
    @State var source: ActiveEnergySource = .activityLevel
    @State var activityLevel: ActivityLevel = .lightlyActive
    @State var intervalType: HealthIntervalType = .average
    @State var interval: HealthInterval = .init(3, .day)
    @State var applyCorrection: Bool = false
    @State var correctionType: CorrectionType = .divide
    @State var correctionInput = DoubleInput(automaticallySubmitsValues: true)
    @State var manualInput = DoubleInput(automaticallySubmitsValues: true)

    @State var activityLevelValuesInKcal: [ActivityLevel: Double] = [:]
    @State var hasFetchedHealthKitValues: Bool = false
    @State var healthKitAverageValuesInKcal: [HealthInterval: Double] = [:]
    @State var healthKitSameDayValueInKcal: Double? = nil
    @State var healthKitPreviousDayValueInKcal: Double? = nil
    @State var handleChangesTask: Task<Void, Error>? = nil

    @State var showingActivityLevelInfo = false
    @State var showingActiveEnergyInfo = false

    @State var hasFocusedCustomField: Bool = true
    @State var hasAppeared = false

    let saveHandler: (HealthDetails.Maintenance.Estimate.ActiveEnergy, Bool) -> ()

    init(
        date: Date,
        activeEnergy: HealthDetails.Maintenance.Estimate.ActiveEnergy,
        restingEnergyInKcal: Double?,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        saveHandler: @escaping (HealthDetails.Maintenance.Estimate.ActiveEnergy, Bool) -> ()
    ) {
        self.date = date
        self.restingEnergyInKcal = restingEnergyInKcal
        self.healthProvider = healthProvider
        self.saveHandler = saveHandler
        _isPresented = isPresented

        let energyUnit = healthProvider.settingsProvider.energyUnit
        _activeEnergyInKcal = State(initialValue: activeEnergy.kcal)
        _manualInput = State(initialValue: DoubleInput(
            double: activeEnergy.kcal.convertEnergy(from: .kcal, to: energyUnit),
            automaticallySubmitsValues: true
        ))

        _source = State(initialValue: activeEnergy.source)
        _activityLevel = State(initialValue: activeEnergy.activityLevel ?? .default)
        let healthKitFetchSettings = activeEnergy.healthKitFetchSettings ?? HealthKitFetchSettings()
        _intervalType = State(initialValue: healthKitFetchSettings.intervalType)
        _interval = State(initialValue: healthKitFetchSettings.interval)
   
        if let correction = healthKitFetchSettings.correction {
            _applyCorrection = State(initialValue: true)
            _correctionType = State(initialValue: correction.type)
            
            let correctionDouble = switch correction.type {
            case .add, .subtract:
                correction.value.convertEnergy(from: .kcal, to: energyUnit)
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
            case .activityLevel:
                activityLevelSection
            case .healthKit:
                healthSections
            }
        }
        .navigationTitle("Active Energy")
        .toolbar { toolbarContent }
        .onAppear(perform: appeared)
        .onChange(of: scenePhase, scenePhaseChanged)
        .sheet(isPresented: $showingActivityLevelInfo) { ActivityLevelInfo() }
        .sheet(isPresented: $showingActiveEnergyInfo) { ActiveEnergyInfo() }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .scrollDismissesKeyboard(.interactively)
    }

    func appeared() {
        if !hasAppeared {
            Task {
                try await calculateActivityLevelValues()
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
            activeEnergyInKcal?.convertEnergy(from: .kcal, to: energyUnit)
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

    var dateSection: some View {
        Section {
            HStack {
                Text("Date")
                Spacer()
                Text(date.shortDateString)
            }
        }
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
    
    var correctionValueInKcalIfEnergy: Double? {
        guard let double = correctionInput.double else { return nil }

        return switch correctionType {
        case .add, .subtract:
            double.convertEnergy(from: energyUnit, to: .kcal)
        case .multiply, .divide:
            double
        }
    }

    var activeEnergy: HealthDetails.Maintenance.Estimate.ActiveEnergy {
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
            kcal: activeEnergyInKcal,
            source: source,
            activityLevel: source == .activityLevel ? activityLevel : nil,
            healthKitFetchSettings: source == .healthKit ? healthKitFetchSettings : nil
        )
    }
    
    func handleChanges() {
        handleChangesTask?.cancel()
        handleChangesTask = Task {
            
            /// Equation Values
            if source == .activityLevel {
                try await calculateActivityLevelValues()
                try Task.checkCancellation()
                await MainActor.run {
                    setActivityLevelValue()
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
    
    func calculateActivityLevelValues() async throws {
        guard let restingEnergyInKcal else { return }
        var dict: [ActivityLevel: Double] = [:]
        for activityLevel in ActivityLevel.allCases {
            let kcal = activityLevel.calculate(for: restingEnergyInKcal)
//            let total = activityLevel.scaleFactor * restingEnergyInKcal
//            let kcal = total - restingEnergyInKcal
            dict[activityLevel] = kcal
        }
        await MainActor.run { [dict] in
            withAnimation {
                activityLevelValuesInKcal = dict
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
                        .active,
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
        
        let sameDayValue = await HealthStore.energy(.active, on: date, in: .kcal)
        let previousDayValue = await HealthStore.energy(.active, on: date.moveDayBy(-1), in: .kcal)

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
            activeEnergyInKcal = value == 0 ? nil : value
        }
        setCustomInput()
    }
    
    func setActivityLevelValue() {
        withAnimation {
            activeEnergyInKcal = activityLevelValuesInKcal[activityLevel]
        }
        setCustomInput()
    }
    
    func setCustomInput() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            manualInput.setDouble(
                activeEnergyInKcal?
                    .convertEnergy(from: .kcal, to: energyUnit)
                    .rounded(.towardZero)
            )
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
            isRestingEnergy: false,
            energyInKcal: $activeEnergyInKcal,
            energyUnitString: energyUnit.abbreviation
        )
    }
    
    var activityLevelSection: some View {
        let binding = Binding<ActivityLevel>(
            get: { activityLevel },
            set: { newValue in
                withAnimation {
                    activityLevel = newValue
                }
                handleChanges()
            }
        )
        
        var footer: some View {
            Button {
                showingActivityLevelInfo = true
            } label: {
                Text("Learn more…")
                    .font(.footnote)
            }
        }

        func string(for activityLevel: ActivityLevel) -> String {
            var string = activityLevel.name
            if restingEnergyInKcal != nil, let kcal = activityLevelValuesInKcal[activityLevel] {
                let value = kcal.convertEnergy(from: .kcal, to: energyUnit)
                string += " • \(value.formattedEnergy) \(energyUnit.abbreviation)"
            }
            return string
        }

        return Section(footer: footer) {
            Picker("Activity Level", selection: binding) {
                ForEach(ActivityLevel.allCases, id: \.self) {
                    Text(string(for: $0)).tag($0)
                }
            }
            .pickerStyle(.wheel)
        }
    }
    
    var sourceSection: some View {
        
        let binding = Binding<ActiveEnergySource>(
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
            Picker("Active Energy", selection: binding) {
                ForEach(ActiveEnergySource.allCases, id: \.self) {
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
                    "Use the Active Energy data recorded in the Apple Health app."
                case .activityLevel:
                    "Apply a multiplier on your Resting Energy based on how active you are."
                case .manual:
                    "Enter your Active Energy manually."
                }
            }
            return Text(description)
        }
        
        return Section {
            pickerRow
            descriptionRow
        }
    }
    
    var explanation: some View {
        var header: some View {
            Text("About Active Energy")
                .textCase(.none)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(Color(.label))
        }
        
        var footer: some View {
            Button {
                showingActiveEnergyInfo = true
            } label: {
                Text("Learn more…")
                    .font(.footnote)
            }
        }
        
        return Section {
            VStack(alignment: .leading) {
                Text("Your Active Energy is the energy burnt over and above your Resting Energy use. You can set it in three ways.")
            }
        }
    }
    
    var manualSection: some View {
        func handleCustomValue() {
            guard source == .manual else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let kcal = manualInput.double?.convertEnergy(from: energyUnit, to: .kcal)
                withAnimation {
                    activeEnergyInKcal = kcal
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
    
    func save() {
        let shouldResync = source == .healthKit
        saveHandler(activeEnergy, shouldResync)
    }
}

#Preview("Demo") {
    DemoView()
}
