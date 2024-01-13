import SwiftUI
import SwiftSugar
import PrepShared

let DefaultNumberOfMovingAveragePoints = 7
let MaxNumberOfMovingAveragePoints = 7

struct WeightChangePointForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    @Bindable var healthProvider: HealthProvider

    let healthDetailsDate: Date
    let initialPoint: WeightChangePoint
    let isEndWeight: Bool
    
    @State var weightInKg: Double?
    @State var useMovingAverage: Bool
    @State var movingAverageInterval: HealthInterval
    @State var points: [WeightChangePoint.MovingAverage.Point]
    
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    let saveHandler: (WeightChangePoint) -> ()
    
    @State var hasFetchedBackendWeights: Bool = false
    @State var backendWeights: [Date: HealthDetails.Weight] = [:]
    @State var handleChangesTask: Task<Void, Error>? = nil
    @State var hasAppeared = false

    init(
        date: Date,
        point: WeightChangePoint,
        isEndWeight: Bool = false,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false),
        saveHandler: @escaping (WeightChangePoint) -> ()
    ) {
        self.healthDetailsDate = date
        self.initialPoint = point
        self.healthProvider = healthProvider
        self.isEndWeight = isEndWeight
        self.saveHandler = saveHandler
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: date.isToday)
        
        _weightInKg = State(initialValue: point.kg)
        _useMovingAverage = State(initialValue: point.movingAverage != nil)
        _movingAverageInterval = State(initialValue: point.movingAverage?.interval ?? .init(DefaultNumberOfMovingAveragePoints, .day))
        _points = State(initialValue: point.defaultPoints)
    }

    var body: some View {
        Form {
            notice
            dateSection
            movingAverageSection
            weights
            explanation
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .onAppear(perform: appeared)
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isLegacy && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    func appeared() {
        if !hasAppeared {
            Task {
                try await fetchBackendWeights()
            }
            hasAppeared = true
        }
    }

    var pointDate: Date {
        initialPoint.date
    }
    
    var dateSection: some View {
        HStack {
            Text("Date")
            Spacer()
            Text(pointDate.shortDateString)
        }
    }
    
    var title: String {
        "\(isEndWeight ? "Ending" : "Starting") Weight"
    }
    
    func setDismissDisabled() {
        dismissDisabled = isLegacy && isEditing && isDirty
    }
    
    var bodyMassUnit: BodyMassUnit { settingsProvider.bodyMassUnit }

    var bottomValue: some View {
        
        var double: Double? {
            guard let weightInKg else { return nil }
            let value = BodyMassUnit.kg
                .doubleComponent(weightInKg, in: bodyMassUnit)
            return abs(value)
        }
        
        var int: Int? {
            guard let weightInKg,
                  let value = BodyMassUnit.kg.intComponent(
                    weightInKg,
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
            doubleUnitString: bodyMassUnit.doubleUnitString
        )
    }
    
    func updatePoint(_ point: WeightChangePoint.MovingAverage.Point, with weight: HealthDetails.Weight) {
        Task {
            guard let index = points.firstIndex(where: { $0.id == point.id }) else {
                return
            }
            backendWeights[point.date] = weight
            await MainActor.run {
                points[index].weight = weight
            }
            await healthProvider.saveWeight(weight, for: point.date)
            handleChanges()
        }
    }
    
    var weights: some View {
        func link(for point: WeightChangePoint.MovingAverage.Point) -> some View {
            func valueText(_ weightInKg: Double) -> some View {
                var valueString: String {
                    let double = "\(double.cleanHealth) \(doubleUnitString)"
                    return if let int, let intUnitString {
                        "\(int) \(intUnitString) \(double)"
                    } else {
                        double
                    }
                }
                
                var double: Double {
                    BodyMassUnit.kg.doubleComponent(weightInKg, in: bodyMassUnit)
                }
                
                var int: Int? {
                    BodyMassUnit.kg.intComponent(weightInKg, in: bodyMassUnit)
                }
                
                var intUnitString: String? { bodyMassUnit.intUnitString }
                var doubleUnitString: String { bodyMassUnit.doubleUnitString }
                
                return Text(valueString)
            }
            
            return NavigationLink {
                WeightForm(
                    date: point.date,
                    weight: point.weight,
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
//                    dismissDisabled: $dismissDisabled,
                    save: { weight in
                        updatePoint(point, with: weight)
                    }
                )
            } label: {
                HStack {
                    Text(point.date.shortDateString)
                    Spacer()
                    if let weightInKg = point.weight.weightInKg {
                        valueText(weightInKg)
                    } else {
                        Text("Not Set")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isLegacy && isEditing)
        }
        
        return Section {
            ForEach(points, id: \.self) { point in
                link(for: point)
            }
        }
    }
    
    var isLegacy: Bool {
        healthDetailsDate.startOfDay < Date.now.startOfDay
    }
    
    @ViewBuilder
    var notice: some View {
        if isLegacy {
            NoticeSection.legacy(healthDetailsDate)
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
    
    func save() {
        saveHandler(point)
    }
    
    var point: WeightChangePoint {
        var movingAverage: WeightChangePoint.MovingAverage? {
            guard useMovingAverage else { return nil }
            return .init(
                interval: movingAverageInterval,
                points: points
            )
        }
        
        var weight: HealthDetails.Weight? {
            guard !useMovingAverage, let firstPoint = points.first else { return nil }
            return firstPoint.weight
        }
        
        return .init(
            date: pointDate,
            kg: weightInKg,
            weight: weight,
            movingAverage: movingAverage
        )
    }
    
    func undo() {
//        isDirty = false
//        useMovingAverage = true
//        movingAverageInterval = 7
    }
    
    func setIsDirty() {
//        isDirty = useMovingAverage != true
//        || movingAverageInterval != 7
    }
    
    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("This is used to determine your weight change, which is then used to calculate your Adaptive Maintenance Energy.\n\nYou can choose to use a moving average of multiple prior days to smooth out any short-term fluctuations.")
            }
        }
    }
    
    func handleChanges() {
        handleChangesTask?.cancel()
        handleChangesTask = Task {
            if hasFetchedBackendWeights {
                await MainActor.run {
                    setPoints()
                }
            } else {
                try await fetchBackendWeights()
            }
            try Task.checkCancellation()

            await MainActor.run {
                setIsDirty()
                if !isLegacy {
                    save()
                }
            }
        }
    }
    
    func datesForPoints(numberOfDays: Int) -> [Date] {
        var dates: [Date] = []
        for i in 0..<numberOfDays {
            dates.append(point.date.moveDayBy(-i))
        }
        return dates
    }
    
    var allPossibleDatesForMovingAverage: [Date] {
        datesForPoints(numberOfDays: MaxNumberOfMovingAveragePoints)
    }

    var datesForPoints: [Date] {
        let numberOfDays = useMovingAverage ? movingAverageInterval.numberOfDays : 1
        return datesForPoints(numberOfDays: numberOfDays)
    }

    func fetchBackendWeights() async throws {
        let dict = try await withThrowingTaskGroup(
            of: (Date, HealthDetails.Weight?).self,
            returning: [Date: HealthDetails.Weight].self
        ) { taskGroup in
            
            for date in allPossibleDatesForMovingAverage {
                taskGroup.addTask {
                    let weight = await healthProvider.fetchOrCreateBackendWeight(for: date)
                    return (date, weight)
                }
            }

            var dict = [Date : HealthDetails.Weight]()

            while let tuple = try await taskGroup.next() {
                dict[tuple.0] = tuple.1
            }
            
            return dict
        }
        
        await MainActor.run { [dict] in
            withAnimation {
                backendWeights = dict
            }
            setPoints()
            hasFetchedBackendWeights = true
        }
    }
    
    func setPoints() {
        var points: [WeightChangePoint.MovingAverage.Point] = []
        for date in datesForPoints {
            points.append(.init(date: date, weight: backendWeights[date] ?? .init()))
        }
        withAnimation {
            self.points = points
            self.weightInKg = points.average
        }
    }
    
    var isDisabled: Bool {
        isLegacy && !isEditing
    }
    
    var movingAverageSection: some View {
        let binding = Binding<Bool>(
            get: { useMovingAverage },
            set: { newValue in
                withAnimation {
                    useMovingAverage = newValue
                }
                handleChanges()
            }
        )
        let intervalBinding = Binding<HealthInterval>(
            get: { movingAverageInterval },
            set: { newValue in
                withAnimation {
                    movingAverageInterval = newValue
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    handleChanges()
                }
            }
        )
        
        var toggle: some View {
            HStack {
                Text("Use a Moving Average")
                    .layoutPriority(1)
                Spacer()
                Toggle("", isOn: binding)
            }
            .disabled(!isEditing)
            .foregroundStyle(isEditing ? .primary : .secondary)
        }
        
        @ViewBuilder
        var intervalPicker: some View {
            if useMovingAverage {
                IntervalPicker(
                    interval: intervalBinding,
                    periods: [.day],
                    ranges: [
                        .day: 2...MaxNumberOfMovingAveragePoints,
                    ],
                    isDisabled: Binding<Bool>(
                        get: { isDisabled },
                        set: { _ in }
                    )
                )
            }
        }
        
        return Section {
            toggle
            intervalPicker
        }
    }
}

//#Preview("Current") {
//    NavigationView {
//        WeightChangePointForm()
//    }
//}

//
//#Preview("Past") {
//    NavigationView {
//        WeightChangePointForm(
//            healthDetailsDate: MockPastDate
//        )
//    }
//}

#Preview("Demo") {
    DemoView()
}
