import SwiftUI
import PrepShared

struct DietaryEnergyPointForm: View {

    @Environment(\.scenePhase) var scenePhase

    @Bindable var healthProvider: HealthProvider
    @Binding var isPresented: Bool

    let healthDetailsDate: Date
    let pointDate: Date
    let averageEnergyInKcal: Double?
    
    @State var source: DietaryEnergyPointSource
    @State var energyInKcal: Double?

    @State var manualInput: DoubleInput

    @State var showingInfo = false
    @State var hasFocusedCustomField: Bool = true
    @State var hasAppeared = false

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
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        saveHandler: @escaping (DietaryEnergyPoint) -> ()
    ) {
        self.healthDetailsDate = date
        self.pointDate = point.date
        self.saveHandler = saveHandler
        self.healthProvider = healthProvider
        self.averageEnergyInKcal = averageEnergyInKcal
        _isPresented = isPresented
        
        let kcal = point.source == .notCounted ? nil : point.kcal
        _source = State(initialValue: point.source)
        _energyInKcal = State(initialValue: kcal)
        _manualInput = State(initialValue: DoubleInput(
            double: kcal.convertEnergy(
                from: .kcal,
                to: healthProvider.settingsProvider.energyUnit
            ),
            automaticallySubmitsValues: true
        ))
    }

    var body: some View {
        Form {
            dateSection
            sourcePicker
            if source == .manual {
                manualSection
            }
            missingLogDataSection
            missingHealthKitDataSection
            notCountedSection
        }
        .navigationTitle("Dietary Energy")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .onAppear(perform: appeared)
        .onChange(of: scenePhase, scenePhaseChanged)
        .sheet(isPresented: $showingInfo) { AdaptiveDietaryEnergyInfo() }
        .safeAreaInset(edge: .bottom) { bottomValue }
    }
    
    @ViewBuilder
    var missingLogDataSection: some View {
        if source == .log, energyInKcal == nil {
            NoticeSection(
                style: .plain,
                notice: .init(
                    title: "No Logged Foods",
                    message: "There are no foods logged on this date.\n\nConsider marking it as fasted if you actually hadn't consumed anything, so that it would be set at 0 \(energyUnit.abbreviation).\n\nIf you can't accurately remember what you had consumed, choose '\(DietaryEnergyPointSource.notCounted.name)', to ignore this day and not count it towards your daily average.",
                    imageName: "questionmark.app.dashed"
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
                    imageName: "questionmark.app.dashed"
                )
            )
        }
    }
    
    @ViewBuilder
    var notCountedSection: some View {
        if source == .notCounted {
            NoticeSection(
                style: .plain,
                notice: .init(
                    title: DietaryEnergyPointSource.notCounted.name,
                    message: "This day's dietary energy is being ignored and will not count towards your daily average.",
                    imageName: DietaryEnergyPointSource.notCounted.image
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
        let kcal = await HealthStore.dietaryEnergyTotalInKcal(for: pointDate)
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
            manualInput.setDouble(
                energyInKcal?
                    .convertEnergy(from: .kcal, to: energyUnit)
                    .rounded(.towardZero)
            )
        }
    }

    func fetchLogValue() async throws {
        let kcal = await DayProvider.fetchBackendEnergyInKcal(for: pointDate)
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
        if newValue == .manual {
            hasFocusedCustomField = false
        }
        withAnimation {
            source = newValue
        }
        handleChanges()
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
            case .fasted, .notCounted, .manual:
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
       }
    }

    var dateSection: some View {
        Section {
            HStack {
                Text("Date")
                Spacer()
                Text(pointDate.shortDateString)
            }
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
            )
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
    
    func save() {
        saveHandler(dietaryEnergyPoint)
        
        /// Save the point in its date's `Day` as well
        var point = dietaryEnergyPoint
        if point.source == .notCounted {
            point.kcal = nil
        }
        healthProvider.saveDietaryEnergyPoint(point)
    }
    
    var dietaryEnergyPoint: DietaryEnergyPoint {
        .init(
            date: pointDate,
            kcal: energyInKcal,
            source: source
        )
    }
  
    var energyUnit: EnergyUnit { healthProvider.settingsProvider.energyUnit }

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
                
            case .notCounted, .manual:
                break
            }

            await MainActor.run {
                save()
            }
        }
    }
    
    var manualSection: some View {
        func handleCustomValue() {
            guard source == .manual else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let kcal = manualInput.double?.convertEnergy(from: energyUnit, to: .kcal)
                withAnimation {
                    energyInKcal = kcal
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    handleChanges()
                }
            }
        }
        
        return SingleUnitMeasurementTextField(
            title: healthProvider.settingsProvider.unitString(for: .energy),
            doubleInput: $manualInput,
            hasFocused: $hasFocusedCustomField,
            delayFocus: true,
            footer: nil,
            handleChanges: handleCustomValue
        )
    }
    
    var explanation: some View {
        var footer: some View {
            Button {
                showingInfo = true
            } label: {
                Text("Learn more…")
                    .font(.footnote)
            }
        }

        return Section(footer: footer) {
                Text("This is the dietary energy being used for this date when calculating your Adaptive Maintenance Energy. You can set it in multiple ways.")
        }
    }
}

#Preview("Demo") {
    DemoView()
}
