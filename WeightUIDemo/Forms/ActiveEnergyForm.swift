import SwiftUI
import PrepShared

struct ActiveEnergyForm: View {

    @Environment(\.dismiss) var dismiss
    @Environment(\.scenePhase) var scenePhase

    @Bindable var settingsProvider: SettingsProvider
    @Bindable var healthProvider: HealthProvider
    
    let date: Date
    let initialActiveEnergy: HealthDetails.Maintenance.Estimate.ActiveEnergy
    let restingEnergyInKcal: Double?

    @State var activeEnergyInKcal: Double?
    @State var source: ActiveEnergySource = .activityLevel
    @State var activityLevel: ActivityLevel = .lightlyActive
    @State var intervalType: HealthIntervalType = .average
    @State var interval: HealthInterval = .init(3, .day)
    @State var applyCorrection: Bool = false
    @State var correctionType: CorrectionType = .divide
    @State var correctionInput = DoubleInput(automaticallySubmitsValues: true)
    @State var customInput = DoubleInput(automaticallySubmitsValues: true)

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

    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    let saveHandler: (HealthDetails.Maintenance.Estimate.ActiveEnergy) -> ()

    init(
        date: Date,
        activeEnergy: HealthDetails.Maintenance.Estimate.ActiveEnergy,
        restingEnergyInKcal: Double?,
        settingsProvider: SettingsProvider,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false),
        saveHandler: @escaping (HealthDetails.Maintenance.Estimate.ActiveEnergy) -> ()
    ) {
        self.date = date
        self.initialActiveEnergy = activeEnergy
        self.restingEnergyInKcal = restingEnergyInKcal
        self.healthProvider = healthProvider
        self.settingsProvider = settingsProvider
        self.saveHandler = saveHandler
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: date.isToday)

        _activeEnergyInKcal = State(initialValue: activeEnergy.kcal)
        _customInput = State(initialValue: DoubleInput(
            double: activeEnergy.kcal.convertEnergy(
                from: .kcal,
                to: settingsProvider.energyUnit
            ),
            automaticallySubmitsValues: true
        ))

        _source = State(initialValue: activeEnergy.source)
        _activityLevel = State(initialValue: activeEnergy.activityLevel)
        _intervalType = State(initialValue: activeEnergy.healthKitSyncSettings.intervalType)
        _interval = State(initialValue: activeEnergy.healthKitSyncSettings.interval)
   
        if let correction = activeEnergy.healthKitSyncSettings.correctionValue {
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
    
    var body: some View {
        Form {
            notice
            explanation
            sourceSection
            switch source {
            case .userEntered:
                customSection
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
        .navigationBarBackButtonHidden(isLegacy && isEditing)
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
        .onChange(of: isEditing) { _, _ in
            handleChanges()
            setDismissDisabled()
        }
    }
    
    func setDismissDisabled() {
        dismissDisabled = isLegacy && isEditing && isDirty
    }

    func appeared() {
        if !hasAppeared {
            Task {
                try await calculateActivityLevelValues()
                try await fetchHealthKitValues()
            }
            hasAppeared = true
        }

        if isEditing {
            /// Triggers equations to re-calculate or HealthKit to resync when we pop back from an equation variable. Delay this if not the first appearance so that we get to see the animation of the value changing.
            DispatchQueue.main.asyncAfter(deadline: .now() + (hasAppeared ? 0.3 : 0)) {
                handleChanges()
            }
        }
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
    
    var energyUnit: EnergyUnit { settingsProvider.energyUnit }

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

    @ViewBuilder
    var notice: some View {
        if isLegacy {
            NoticeSection.legacy(date, isEditing: $isEditing)
        }
    }

    var toolbarContent: some ToolbarContent {
        topToolbarContent(
            isEditing: $isEditing,
            isDirty: $isDirty,
            isPast: isLegacy,
            dismissAction: { isPresented = false },
            undoAction: undo,
            saveAction: save
        )
    }
    
    var isDisabled: Bool {
        isLegacy && !isEditing
    }
    
    var controlColor: Color {
        isDisabled ? .secondary : .primary
    }
    
    var isLegacy: Bool {
        date.startOfDay < Date.now.startOfDay
    }
    
    //MARK: - Sections
    
    var correctionValueInKcalIfEnergy: Double? {
        guard let double = correctionInput.double else { return nil }

        return switch correctionType {
        case .add, .subtract:       double.convertEnergy(from: energyUnit, to: .kcal)
        case .multiply, .divide:    double
        }
    }

    var activeEnergy: HealthDetails.Maintenance.Estimate.ActiveEnergy {
        .init(
            kcal: activeEnergyInKcal,
            source: source,
            activityLevel: activityLevel,
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
        guard isEditing else { return }

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
                    try await fetchHealthKitValues()
                }
                try Task.checkCancellation()
            }

            await MainActor.run {
                setIsDirty()
                if !isLegacy {
                    save()
                }
            }
        }
    }
    
    func calculateActivityLevelValues() async throws {
        guard let restingEnergyInKcal else { return }
        var dict: [ActivityLevel: Double] = [:]
        for activityLevel in ActivityLevel.allCases {
            let total = activityLevel.scaleFactor * restingEnergyInKcal
            let kcal = total - restingEnergyInKcal
            dict[activityLevel] = kcal
        }
        await MainActor.run { [dict] in
            withAnimation {
                activityLevelValuesInKcal = dict
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
                    let kcal = try await HealthStore.activeEnergy(
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
        
        let sameDayValue = try await HealthStore.activeEnergy(on: date, in: .kcal)
        let previousDayValue = try await HealthStore.activeEnergy(on: date.moveDayBy(-1), in: .kcal)

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
            customInput.setDouble(
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
            isEditing: $isEditing,
            applyCorrection: $applyCorrection,
            correctionType: $correctionType,
            correctionInput: $correctionInput,
            handleChanges: handleChanges,
            isRestingEnergy: false,
            energyInKcal: $activeEnergyInKcal
        )
        .environment(settingsProvider)
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
        
        @ViewBuilder
        var footer: some View {
            if !isDisabled {
                Button {
                    showingActivityLevelInfo = true
                } label: {
                    Text("Learn more…")
                        .font(.footnote)
                }
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
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1)
        }
    }
    
    var sourceSection: some View {
        
        let binding = Binding<ActiveEnergySource>(
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
            Picker("Active Energy", selection: binding) {
                ForEach(ActiveEnergySource.allCases, id: \.self) {
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
                    "Use the Active Energy data recorded in the Apple Health app."
                case .activityLevel:
                    "Apply a multiplier on your Resting Energy based on how active you are."
                case .userEntered:
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
    
    var customSection: some View {
        func handleCustomValue() {
            guard source == .userEntered else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let kcal = customInput.double?.convertEnergy(from: energyUnit, to: .kcal)
                withAnimation {
                    activeEnergyInKcal = kcal
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
            isDisabled: Binding<Bool>(
                get: { isDisabled },
                set: { _ in }
            ),
            handleChanges: handleCustomValue
        )
    }
    
    //MARK: - Actions
    
    func undo() {
        activeEnergyInKcal = initialActiveEnergy.kcal
        customInput = DoubleInput(
            double: initialActiveEnergy.kcal.convertEnergy(
                from: .kcal,
                to: settingsProvider.energyUnit
            ),
            automaticallySubmitsValues: true
        )

        source = initialActiveEnergy.source
        activityLevel = initialActiveEnergy.activityLevel
        intervalType = initialActiveEnergy.healthKitSyncSettings.intervalType
        interval = initialActiveEnergy.healthKitSyncSettings.interval
   
        if let correction = initialActiveEnergy.healthKitSyncSettings.correctionValue {
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
        isDirty = activeEnergy != initialActiveEnergy
    }
    
    func save() {
        saveHandler(activeEnergy)
    }
}
//
//#Preview("Current") {
//    NavigationView {
//        ActiveEnergyForm(
//            settingsProvider: SettingsProvider(),
//            healthProvider: MockCurrentProvider
//        )
//    }
//}
//
//#Preview("Past") {
//    NavigationView {
//        ActiveEnergyForm(
//            settingsProvider: SettingsProvider(),
//            healthProvider: MockPastProvider
//        )
//    }
//}

#Preview("Demo") {
    DemoView()
}
