import SwiftUI
import PrepShared

struct DietaryEnergyPointForm: View {

    @Environment(\.scenePhase) var scenePhase

    @Bindable var settingsProvider: SettingsProvider
    @Bindable var healthProvider: HealthProvider

    let healthDetailsDate: Date
    let initialPoint: DietaryEnergyPoint
    let averageEnergyInKcal: Double?
    
    @State var source: DietaryEnergyPointSource
    @State var energyInKcal: Double?

    @State var customInput: DoubleInput

    @State var showingInfo = false
    @State var hasFocusedCustomField: Bool = true
    @State var hasAppeared = false

    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    @State var hasFetchedLogValue: Bool = false
    @State var logValueInKcal: Double?

    @State var hasFetchedHealthKitValue: Bool = false
    @State var healthKitValueInKcal: Double?

    @State var handleChangesTask: Task<Void, Error>? = nil

    let saveHandler: (DietaryEnergyPoint) -> ()

    init(
        date: Date,
        point: DietaryEnergyPoint,
        averageEnergyInKcal: Double? = nil,
        settingsProvider: SettingsProvider,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false),
        saveHandler: @escaping (DietaryEnergyPoint) -> ()
    ) {
        self.healthDetailsDate = date
        self.initialPoint = point
        self.saveHandler = saveHandler
        self.settingsProvider = settingsProvider
        self.healthProvider = healthProvider
        self.averageEnergyInKcal = averageEnergyInKcal
        _isEditing = State(initialValue: point.date.isToday)
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        
        let kcal = point.source == .useAverage ? nil : point.kcal
        _source = State(initialValue: point.source)
        _energyInKcal = State(initialValue: kcal)
        _customInput = State(initialValue: DoubleInput(
            double: kcal.convertEnergy(
                from: .kcal,
                to: settingsProvider.energyUnit
            ),
            automaticallySubmitsValues: true
        ))
    }

    var body: some View {
        Form {
            notice
            sourcePicker
            if source == .userEntered {
                customSection
            }
            missingLogDataSection
            missingHealthKitDataSection
            notCountedSection
//            explanation
        }
        .navigationTitle(initialPoint.date.shortDateString)
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .onAppear(perform: appeared)
        .onChange(of: scenePhase, scenePhaseChanged)
        .sheet(isPresented: $showingInfo) { AdaptiveDietaryEnergyInfo() }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isLegacy && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    @ViewBuilder
    var missingLogDataSection: some View {
        if source == .log, energyInKcal == nil {
            NoticeSection(
                style: .plain,
                notice: .init(
                    title: "No Logged Foods",
                    message: "There are no foods logged on this date.\n\nConsider marking it as fasted if you actually hadn't consumed anything, so that it would be set at 0 \(energyUnit.abbreviation).\n\nIf you can't accurately remember what you had consumed, choose 'Exclude this Day', to ignore this day and not count it towards your daily average.",
                    imageName: "questionmark.app.dashed",
                    isEditing: $isEditing
                )
            )
        }
    }
    
    @ViewBuilder
    var missingHealthKitDataSection: some View {
        if source == .healthKit, energyInKcal == nil {
            NoticeSection(
                style: .plain,
                notice: .init(
                    title: "Missing Data or Permissions",
                    message: "No data was fetched from Apple Health. This could be because there isn't any data available for \(pointDate.shortDateString) or you have not provided permission to read it.\n\nYou can check for permissions in:\nSettings > Privacy & Security > Health > Prep",
                    imageName: "questionmark.app.dashed",
                    isEditing: $isEditing
                )
            )
        }
    }
    
    @ViewBuilder
    var notCountedSection: some View {
        if source == .useAverage {
            NoticeSection(
                style: .plain,
                notice: .init(
                    title: "Excluded",
                    message: "This day's dietary energy is being ignored and will not count towards your daily average.",
                    imageName: "pencil.slash",
                    isEditing: $isEditing
                )
            )
        }
    }
    func appeared() {
        if !hasAppeared {
            Task {
                try await fetchLogValue()
                try await fetchHealthKitValue()
            }
            hasAppeared = true
        }
    }

    func scenePhaseChanged(old: ScenePhase, new: ScenePhase) {
        switch new {
        case .active:
            Task {
                try await fetchHealthKitValue()
            }
        default:
            break
        }
    }
    
    func fetchHealthKitValue() async throws {
        let kcal = try await HealthStore.dietaryEnergyTotalInKcal(for: pointDate)
        await MainActor.run { [kcal] in
            withAnimation {
                healthKitValueInKcal = kcal?
                    .rounded(.towardZero) /// Use Health App's rounding (towards zero)
            }
            if source == .healthKit {
                setHealthKitValue()
            }
            hasFetchedHealthKitValue = true
        }
    }
    
    func setHealthKitValue() {
        withAnimation {
            energyInKcal = healthKitValueInKcal
        }
        setCustomInput()
    }
    
    func setCustomInput() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            customInput.setDouble(
                energyInKcal?
                    .convertEnergy(from: .kcal, to: energyUnit)
                    .rounded(.towardZero)
            )
        }
    }

    func fetchLogValue() async throws {
        let kcal = healthProvider.fetchBackendEnergyInKcal(for: pointDate)
        await MainActor.run { [kcal] in
            withAnimation {
                logValueInKcal = kcal?
                    .rounded(.towardZero)
            }
            if source == .log {
                setLogValue()
            }
            hasFetchedLogValue = true
        }
    }
    
    func setLogValue() {
        withAnimation {
            energyInKcal = logValueInKcal
        }
        setCustomInput()
    }

    func setSource(to newValue: DietaryEnergyPointSource) {
        if newValue == .userEntered {
            hasFocusedCustomField = false
        }
        withAnimation {
            source = newValue
        }
        handleChanges()
    }

    var controlColor: Color {
        isDisabled ? .secondary : .primary
    }
    
    var healthKitValueInUserUnit: Double? {
        guard let healthKitValueInKcal else { return nil }
        return EnergyUnit.kcal.convert(healthKitValueInKcal, to: energyUnit)
    }

    var logValueInUserUnit: Double? {
        guard let logValueInKcal else { return nil }
        return EnergyUnit.kcal.convert(logValueInKcal, to: energyUnit)
    }

    var sourcePicker: some View {
        let binding = Binding<DietaryEnergyPointSource>(
            get: { source },
            set: { setSource(to: $0) }
        )
        
        func string(for source: DietaryEnergyPointSource) -> String {
            switch source {
            case .log:
                if let logValueInUserUnit {
                    "\(source.name) • \(logValueInUserUnit.formattedEnergy) \(energyUnit.abbreviation)"
                } else {
                    source.name
                }
            case .healthKit:
                if let healthKitValueInUserUnit {
                    "\(source.name) • \(healthKitValueInUserUnit.formattedEnergy) \(energyUnit.abbreviation)"
                } else {
                    source.name
                }
            case .fasted, .useAverage, .userEntered:
                source.name
            }
        }
        return Section {
            Picker("Source", selection: binding) {
                ForEach(DietaryEnergyPointSource.allCases, id: \.self) {
                    Text(string(for: $0)).tag($0)
                }
            }
            .pickerStyle(.wheel)
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1)
       }
    }
    
    var sourcePicker_: some View {

        func cell(for source: DietaryEnergyPointSource) -> some View {
            var checkmark: some View {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.accentColor)
                    .opacity(self.source == source ? 1 : 0)
                    .animation(.none, value: self.source)
            }
            
            var name: some View {
                Text(source.name)
                    .foregroundStyle(isDisabled ? Color(.secondaryLabel) : Color(.label))
            }
            
            return HStack {
                DietaryEnergyPointSourceImage(source: source)
                name
                Spacer()
                checkmark
            }

        }
            
        return Section {
            ForEach(DietaryEnergyPointSource.allCases) { source in
                Button {
                    setSource(to: source)
                } label: {
                    cell(for: source)
                }
                .disabled(isDisabled)
            }
        }
    }
    
    func setDismissDisabled() {
        dismissDisabled = isLegacy && isEditing && isDirty
    }

    var isLegacy: Bool {
        pointDate.startOfDay < Date.now.startOfDay
//        healthDetailsDate.startOfDay < Date.now.startOfDay
    }
    
    @ViewBuilder
    var notice: some View {
        if isLegacy {
            NoticeSection.legacy(isEditing: $isEditing)
        }
    }
    
    var bottomValue: some View {
        
        var energyValue: Double? {
            guard let energyInKcal else { return nil }
            return EnergyUnit.kcal.convert(energyInKcal, to: energyUnit)
        }
        
        return MeasurementBottomBar(
            double: Binding<Double?>(
                get: { energyValue },
                set: { _ in }
            ),
            doubleString: Binding<String?>(
                get: { energyValue?.formattedEnergy },
                set: { _ in }
            ),
            doubleUnitString: energyUnit.abbreviation,
            emptyValueString: Binding<String>(
                get: { source.emptyValueString },
                set: { _ in }
            ),
            isDisabled: Binding<Bool>(
                get: { !isEditing },
                set: { _ in }
            )
        )
//        return HStack(alignment: .firstTextBaseline, spacing: 5) {
//            Spacer()
//            if let energyValue {
//                Text("\(energyValue.formattedEnergy)")
//                    .contentTransition(.numericText(value: energyValue))
//                    .font(LargeNumberFont)
//                Text("kcal")
//                    .font(LargeUnitFont)
//                    .foregroundStyle(.secondary)
//            } else {
//                ZStack {
//                    
//                    /// dummy text placed to ensure height stays consistent
//                    Text("0")
//                        .font(LargeNumberFont)
//                        .opacity(0)
//
//                    Text(source == .userEntered ? "Not Set" : "Excluded")
//                        .font(LargeUnitFont)
//                        .foregroundStyle(.secondary)
//                }
//            }
//        }
//        .padding(.horizontal, BottomValueHorizontalPadding)
//        .padding(.vertical, BottomValueVerticalPadding)
//        .background(.bar)
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            topToolbarContent(
                isEditing: $isEditing,
                isDirty: $isDirty,
                isPast: isLegacy,
                dismissAction: { isPresented = false },
                undoAction: undo,
                saveAction: save
            )
        }
    }
    
    func save() {
        saveHandler(dietaryEnergyPoint)
        
        /// Save the point in its date's `Day` as well
        var point = dietaryEnergyPoint
        if point.source == .useAverage {
            point.kcal = nil
        }
        healthProvider.saveDietaryEnergyPoint(point)
    }
    
    func undo() {
        energyInKcal = initialPoint.kcal
        customInput = DoubleInput(
            double: initialPoint.kcal.convertEnergy(
                from: .kcal,
                to: energyUnit
            ),
            automaticallySubmitsValues: true
        )
        source = initialPoint.source
    }
    
    func setIsDirty() {
        var initialPoint = initialPoint
        if initialPoint.source == .useAverage {
            initialPoint.kcal = nil
        }
        isDirty = dietaryEnergyPoint != initialPoint
    }
    
    var pointDate: Date {
        initialPoint.date
    }
    
    var dietaryEnergyPoint: DietaryEnergyPoint {
        .init(
            date: pointDate,
            kcal: energyInKcal,
            source: source
        )
    }
  
    var energyUnit: EnergyUnit { settingsProvider.energyUnit }

    func handleChanges() {
        handleChangesTask?.cancel()
        handleChangesTask = Task {
            
            switch source {
            case .log:
                if hasFetchedLogValue {
                    await MainActor.run {
                        setLogValue()
                    }
                } else {
                    try await fetchLogValue()
                }
                try Task.checkCancellation()

            case .healthKit:
                if hasFetchedHealthKitValue {
                    await MainActor.run {
                        setHealthKitValue()
                    }
                } else {
                    try await fetchHealthKitValue()
                }
                try Task.checkCancellation()

            case .fasted:
                await MainActor.run {
                    withAnimation {
                        energyInKcal = 0
                    }
                }
                
            case .useAverage, .userEntered:
                break
            }

            await MainActor.run {
                setIsDirty()
                if !isLegacy {
                    save()
                }
            }
        }
    }
    
    var customSection: some View {
        func handleCustomValue() {
            guard source == .userEntered else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let kcal = customInput.double?.convertEnergy(from: energyUnit, to: .kcal)
                withAnimation {
                    energyInKcal = kcal
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
    
    var isDisabled: Bool {
        isLegacy && !isEditing
    }
    
    var explanation: some View {
        @ViewBuilder
        var footer: some View {
            if !isDisabled {
                Button {
                    showingInfo = true
                } label: {
                    Text("Learn more…")
                        .font(.footnote)
                }
            }
        }

        return Section(footer: footer) {
                Text("This is the dietary energy being used for this date when calculating your Adaptive Maintenance Energy. You can set it in multiple ways.")
        }
    }
}

//#Preview("Current") {
//    NavigationView {
//        DietaryEnergyPointForm()
//    }
//}
//
//#Preview("Past") {
//    NavigationView {
//        DietaryEnergyPointForm(healthDetailsDate: MockPastDate)
//    }
//}

#Preview("Demo") {
    DemoView()
}
