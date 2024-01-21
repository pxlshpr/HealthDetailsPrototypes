import SwiftUI
import SwiftSugar
import PrepShared

struct WeightChangeForm: View {
    
    @Bindable var healthProvider: HealthProvider
    @Binding var isPresented: Bool
    
    let date: Date

    @State var type: WeightChangeType
    @State var weightChangeInKg: Double?
    @State var weightChangeIsPositive: Bool
    @State var doubleInput: DoubleInput
    @State var intInput: IntInput
    @State var points: WeightChange.Points?

    @State var hasFocusedCustomField: Bool = true

    let saveHandler: (WeightChange, Bool) -> ()

    @Binding var startWeight: HealthDetails.Weight?
    @Binding var startWeightMovingAverageWeights: [Date : HealthDetails.Weight]
    @Binding var endWeight: HealthDetails.Weight?
    @Binding var endWeightMovingAverageWeights: [Date : HealthDetails.Weight]

    init(
        date: Date = Date.now,
        weightChange: WeightChange,
        startWeight: Binding<HealthDetails.Weight?>,
        startWeightMovingAverageWeights: Binding<[Date : HealthDetails.Weight]>,
        endWeight: Binding<HealthDetails.Weight?>,
        endWeightMovingAverageWeights: Binding<[Date : HealthDetails.Weight]>,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        saveHandler: @escaping (WeightChange, Bool) -> ()
    ) {
        self.date = date
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
        
        let unit = healthProvider.settingsProvider.bodyMassUnit
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
        
        _startWeight = startWeight
        _startWeightMovingAverageWeights = startWeightMovingAverageWeights
        _endWeight = endWeight
        _endWeightMovingAverageWeights = endWeightMovingAverageWeights
    }
    
    var body: some View {
        Form {
            dateSection
            typePicker
            switch type {
            case .weights:
                weightSections
            case .manual:
                manualSection
                gainOrLossSection
            }
        }
        .navigationTitle("Weight Change")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) { bottomValue }
    }
    
    var dateSection: some View {
        Section {
            HStack {
                Text("Period")
                Spacer()
                Text(intervalString)
            }
        }
    }
    
    var weightSections: some View {
        func section(
            for point: WeightChangePoint,
            title: String,
            isEndWeight: Bool
        ) -> some View {
            var header: some View {
                Text(title)
            }
            
            @ViewBuilder
            var footer: some View {
                if let interval = point.movingAverageInterval {
                    Text("This is a moving average of your weight from \(interval.startDate(with: point.date).shortDateString) to \(point.date.shortDateString)")
                }
            }
            
            let weight = Binding<HealthDetails.Weight?>(
                get: { isEndWeight ? endWeight : startWeight },
                set: { newValue in
                    switch isEndWeight {
                    case true:  endWeight = newValue
                    case false: startWeight = newValue
                    }
                }
            )

            let movingAverageWeights = Binding<[Date : HealthDetails.Weight]>(
                get: { isEndWeight ? endWeightMovingAverageWeights : startWeightMovingAverageWeights },
                set: { newValue in
                    switch isEndWeight {
                    case true:  endWeightMovingAverageWeights = newValue
                    case false: startWeightMovingAverageWeights = newValue
                    }
                }
            )

            return Section(header: header, footer: footer) {
                NavigationLink {
                    WeightChangePointForm(
                        date: date,
                        point: point,
                        weight: weight,
                        movingAverageWeights: movingAverageWeights,
                        isEndWeight: isEndWeight,
                        healthProvider: healthProvider,
                        isPresented: $isPresented,
                        saveHandler: { point, shouldResync in
                            if isEndWeight {
                                points?.end = point
                            } else {
                                points?.start = point
                            }
                            handleChanges(shouldResync)
                        }
                    )
                } label: {
                    HStack {
                        Text(point.date.shortDateString)
                        Spacer()
                        if let kg = point.kg {
                            Text(healthProvider.settingsProvider.bodyMassString(kg))
                        } else {
                            Text(NotSetString)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
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
    
    var bodyMassUnit: BodyMassUnit { healthProvider.settingsProvider.bodyMassUnit }

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
            )
        )
    }
    
    var weightChangeValueIsPositive: Bool {
        guard let value = weightChangeInUserUnit else { return false }
        return value > 0
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
    
    var weightChange: WeightChange {
        .init(
            kg: weightChangeInKg,
            type: type,
            points: points
        )
    }
    
    func save(_ shouldResync: Bool = false) {
        saveHandler(weightChange, shouldResync)
    }
    
    var manualSection: some View {
        func handleCustomValue() {
            guard type == .manual else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let int = intInput.int ?? 0
                let double = doubleInput.double ?? 0
                
                let kg: Double? = if int == 0, double == 0 {
                    nil
                } else {
                    bodyMassUnit.convert(int, double, to: .kg) * (weightChangeIsPositive ? 1 : -1)
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
            settingsProvider: healthProvider.settingsProvider,
            doubleInput: $doubleInput,
            intInput: $intInput,
            hasFocused: $hasFocusedCustomField,
            handleChanges: handleCustomValue
        )
    }
    
    var intervalString: String {
        healthProvider.healthDetails.adaptiveMaintenanceIntervalString
    }
    
    var explanation: some View {
        Section {
            Text("This represents the change in your weight from \(intervalString), which is used to calculate your Adaptive Maintenance Energy.")
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

    func handleChanges(_ shouldResync: Bool = false) {
        switch type {
        case .weights:
            if points == nil {
                points = .init(
                    date: date,
                    interval: healthProvider.healthDetails.maintenance.adaptive.interval
                )
            }
            setWeightChangeInKg(points?.weightChangeInKg)
           
        case .manual:
            break
        }
        
        save(shouldResync)
    }
    
    var typePicker: some View {
        let binding = Binding<WeightChangeType>(
            get: { type },
            set: { newValue in
                if newValue == .manual {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        hasFocusedCustomField = false
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
            .listRowSeparator(.hidden)
        }
        
        var description: String {
            switch type {
            case .manual: "Enter your weight change manually."
            case .weights: "Use your starting and ending weights to calculate your weight change."
            }
        }
        return Section {
            picker
            Text(description)
        }
    }
}

#Preview("DemoView") {
    DemoView()
}
