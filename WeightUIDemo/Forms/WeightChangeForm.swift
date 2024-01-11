import SwiftUI
import SwiftSugar
import PrepShared

struct WeightChangeForm: View {
    
    @Bindable var settingsProvider: SettingsProvider
    @Bindable var healthProvider: HealthProvider

    let date: Date
    let initialWeightChange: WeightChange

    @State var type: WeightChangeType
    @State var weightChangeInKg: Double?
    @State var weightChangeIsPositive: Bool
    @State var doubleInput: DoubleInput
    @State var intInput: IntInput
    @State var points: WeightChange.Points?

    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    @State var hasFocusedCustom: Bool = false

    let saveHandler: (WeightChange) -> ()

    init(
        date: Date = Date.now,
        weightChange: WeightChange,
        healthProvider: HealthProvider,
        settingsProvider: SettingsProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false),
        saveHandler: @escaping (WeightChange) -> ()
    ) {
        self.date = date
        self.initialWeightChange = weightChange
        self.settingsProvider = settingsProvider
        self.healthProvider = healthProvider
        self.saveHandler = saveHandler
        
        _type = State(initialValue: weightChange.type)
        _weightChangeInKg = State(initialValue: weightChange.kg)
        if let kg = weightChange.kg {
            _weightChangeIsPositive = State(initialValue: kg >= 0)
        } else {
            _weightChangeIsPositive = State(initialValue: true)
        }
        _points = State(initialValue: weightChange.points)
        
        let unit = settingsProvider.bodyMassUnit
        let kg = weightChange.kg
        
        let double: Double? = if let kg {
            BodyMassUnit.kg.doubleComponent(kg, in: unit)
        } else {
           nil
        }
        _doubleInput = State(initialValue: DoubleInput(double: double, automaticallySubmitsValues: true))

        let int: Int? = if let kg {
            BodyMassUnit.kg.intComponent(kg, in: unit)
        } else {
           nil
        }
        _intInput = State(initialValue: IntInput(int: int, automaticallySubmitsValues: true))

        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: date.isToday)
    }
    
    var body: some View {
        Form {
            notice
            dateSection
            typePicker
            switch type {
            case .usingPoints:
                weightSections
            case .userEntered:
                customSection
                gainOrLossSection
            }
//            explanation
        }
        .navigationTitle("Weight Change")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isLegacy && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    var dateSection: some View {
        Section {
            HStack {
                Text("Period")
                Spacer()
                Text(dateIntervalString)
            }
        }
    }
    
    var weightSections: some View {
        func section(
            for point: WeightChangePoint,
            title: String,
            isEndWeight: Bool
        ) -> some View {
            Section(title) {
                NavigationLink {
                    WeightChangePointForm(
                        date: date,
                        point: point,
                        isEndWeight: isEndWeight,
                        healthProvider: healthProvider,
                        isPresented: $isPresented,
                        dismissDisabled: $dismissDisabled,
                        saveHandler: { point in
                            if isEndWeight {
                                points?.end = point
                            } else {
                                points?.start = point
                            }
                            handleChanges()
                        }
                    )
                } label: {
                    HStack {
                        Text(point.date.shortDateString)
                        Spacer()
                        if let kg = point.kg {
                            Text("\(BodyMassUnit.kg.convert(kg, to: settingsProvider.bodyMassUnit).clean) \(settingsProvider.bodyMassUnit.abbreviation)")
                        } else {
                            Text("Not Set")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .disabled(isEditing && isLegacy)
            }
        }
        
        return Group {
            if let points {
                section(
                    for: points.end,
                    title: "Ending Weight",
                    isEndWeight: true
                )
                section(
                    for: points.start,
                    title: "Starting Weight",
                    isEndWeight: false
                )
            }
        }
    }

    var gainOrLossSection: some View {
        let binding = Binding<Bool>(
            get: { weightChangeIsPositive },
            set: { newValue in
                withAnimation {
                    weightChangeIsPositive = newValue
                    if let weightChangeInKg {
                        switch newValue {
                        case true:  self.weightChangeInKg = abs(weightChangeInKg)
                        case false: self.weightChangeInKg = abs(weightChangeInKg) * -1
                        }
                    }
                }
                handleChanges()
            }
        )

        var picker: some View {
            Picker("", selection: binding) {
                Text("Gain").tag(true)
                Text("Loss").tag(false)
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
        }
        
        return Group {
            if weightChangeInKg != nil, weightChangeInKg != 0 {
                Section {
                    picker
                }
            }
        }
    }
    
    func setDismissDisabled() {
        dismissDisabled = isLegacy && isEditing && isDirty
    }

    var bodyMassUnit: BodyMassUnit { settingsProvider.bodyMassUnit }

    var weightChangeInUserUnit: Double? {
        weightChangeInKg.convertBodyMass(from: .kg, to: bodyMassUnit)
    }

    var bottomValue: some View {

        var double: Double? {
            guard let weightChangeInKg else { return nil }
            let value = BodyMassUnit.kg
                .doubleComponent(weightChangeInKg, in: bodyMassUnit)
            return abs(value)
        }
        
        var int: Int? {
            guard let weightChangeInKg,
                  let value = BodyMassUnit.kg.intComponent(
                    weightChangeInKg,
                    in: bodyMassUnit
                  )
            else { return nil }
            return abs(value)
        }

        return MeasurementBottomBar(
            int: Binding<Int?>(
                get: { int }, set: { _ in }
            ),
            intUnitString: bodyMassUnit.intUnitString,
            double: Binding<Double?>(
                get: { double }, set: { _ in }
            ),
            doubleString: Binding<String?>(
                get: { double?.cleanHealth }, set: { _ in }
            ),
            doubleUnitString: bodyMassUnit.doubleUnitString,
            prefix: Binding<String?>(
                get: { weightChangeValueIsPositive ? "+" : "-" }, set: { _ in }
            ),
            isDisabled: Binding<Bool>(
                get: { !isEditing },
                set: { _ in }
            )
        )
    }
    
    var isLegacy: Bool {
        date.startOfDay < Date.now.startOfDay
    }
    
    @ViewBuilder
    var notice: some View {
        if isLegacy {
            NoticeSection.legacy(date, isEditing: $isEditing)
        }
    }
    
    var weightChangeValueIsPositive: Bool {
        guard let value = weightChangeInUserUnit else { return false }
        return value > 0
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
    
    var weightChange: WeightChange {
        .init(
            kg: weightChangeInKg,
            type: type,
            points: points
        )
    }
    
    func save() {
        saveHandler(weightChange)
    }
    
    func undo() {
        type = initialWeightChange.type
        points = initialWeightChange.points
        setWeightChangeInKg(initialWeightChange.kg)
    }
    
    func setIsDirty() {
        isDirty = initialWeightChange != weightChange
    }
    
    var customSection: some View {
        func handleCustomValue() {
            guard type == .userEntered else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let int = intInput.int ?? 0
                let double = doubleInput.double ?? 0
                
                let kg: Double? = if int == 0, double == 0 {
                    nil
                } else {
                    settingsProvider.bodyMassUnit.convert(int, double, to: .kg) * (weightChangeIsPositive ? 1 : -1)
                }
                withAnimation {
                    weightChangeInKg = kg
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    handleChanges()
                }
            }
        }

        return MeasurementInputSection(
            type: .weight,
            doubleInput: $doubleInput,
            intInput: $intInput,
            hasFocused: $hasFocusedCustom,
            handleChanges: handleCustomValue
        )
        .environment(settingsProvider)
    }
    
    var dateIntervalString: String {
        let startDate = healthProvider.healthDetails.maintenance.adaptive.interval.startDate(with: date)
        return "\(startDate.shortDateString) to \(date.shortDateString)"
    }
    
    var explanation: some View {
        Section {
            Text("This represents the change in your weight from \(dateIntervalString), which is used to calculate your Adaptive Maintenance Energy.")
        }
    }
    
    func setWeightChangeInKg(_ kg: Double?) {
        weightChangeInKg = kg
        weightChangeIsPositive = if let kg { kg >= 0 } else { true }

        let double: Double? = if let kg {
            BodyMassUnit.kg.doubleComponent(kg, in: bodyMassUnit)
        } else { nil }
        doubleInput = DoubleInput(double: double, automaticallySubmitsValues: true)

        let int: Int? = if let kg {
            BodyMassUnit.kg.intComponent(kg, in: bodyMassUnit)
        } else { nil }
        intInput = IntInput(int: int, automaticallySubmitsValues: true)
    }

    func handleChanges() {
        switch type {
        case .usingPoints:
            if points == nil {
                points = .init(
                    date: date,
                    interval: healthProvider.healthDetails.maintenance.adaptive.interval
                )
            }
            setWeightChangeInKg(points?.weightChangeInKg)
           
        case .userEntered:
            break
        }
        
        setIsDirty()
        if !isLegacy {
            save()
        }
    }
    
    var typePicker: some View {
        let binding = Binding<WeightChangeType>(
            get: { type },
            set: { newValue in
                if newValue == .userEntered {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        hasFocusedCustom = false
                    }
                }
                withAnimation {
                    type = newValue
                }
                handleChanges()
            }
        )
        
        var picker: some View {
            Picker("", selection: binding) {
                ForEach(WeightChangeType.allCases) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .disabled(!isEditing)
            .listRowSeparator(.hidden)
        }
        
        var description: String {
            switch type {
            case .userEntered: "Enter your weight change manually."
            case .usingPoints: "Use your starting and ending weights to calculate your weight change."
            }
        }
        return Section {
            picker
            Text(description)
        }
    }
}

#Preview("Current") {
    NavigationView {
        WeightChangeForm(
            date: Date.now,
            weightChange: .init(),
            healthProvider: MockCurrentProvider,
            settingsProvider: SettingsProvider(settings: .init(bodyMassUnit: .kg)),
            isPresented: .constant(true),
            dismissDisabled: .constant(false),
            saveHandler: { weightChange in
                
            }
        )
    }
}

#Preview("DemoView") {
    DemoView()
}
