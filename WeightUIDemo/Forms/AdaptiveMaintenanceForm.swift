import SwiftUI
import SwiftSugar
import PrepShared

let MaxAdaptiveWeeks: Int = 2

let MinimumAdaptiveEnergyInKcal: Double = 1000

struct AdaptiveMaintenanceForm: View {
    
    @Bindable var healthProvider: HealthProvider
    @Binding var isPresented: Bool

    let date: Date
    
    @State var adaptiveInKcal: Double?
    @State var interval: HealthInterval
    @State var dietaryEnergy: HealthDetails.Maintenance.Adaptive.DietaryEnergy
    @State var weightChange: WeightChange
    
    let saveHandler: (HealthDetails.Maintenance.Adaptive, Bool) -> ()
    
    @State var showingInfo = false

    @State var dietaryEnergyPoints: [DietaryEnergyPoint] = []

    @State var startWeight: HealthDetails.Weight? = nil
    @State var startWeightMovingAverageWeights: [Date : HealthDetails.Weight] = [:]
    @State var endWeight: HealthDetails.Weight? = nil
    @State var endWeightMovingAverageWeights: [Date : HealthDetails.Weight] = [:]

    init(
        date: Date = Date.now,
        adaptive: HealthDetails.Maintenance.Adaptive,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        saveHandler: @escaping (HealthDetails.Maintenance.Adaptive, Bool) -> ()
    ) {
        self.date = date
        self.healthProvider = healthProvider
        self.saveHandler = saveHandler
        _isPresented = isPresented
        
        _adaptiveInKcal = State(initialValue: adaptive.kcal)
        _interval = State(initialValue: adaptive.interval)
        _dietaryEnergy = State(initialValue: adaptive.dietaryEnergy)
        _weightChange = State(initialValue: adaptive.weightChange)
    }

    var body: some View {
        Form {
            dateSection
            intervalSection
            dietaryEnergyLink
            weightChangeLink
            invalidCalculationSection
            explanation
        }
        .navigationTitle("Adaptive")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingInfo) { AdaptiveMaintenanceInfo(interval: $interval) }
        .onAppear(perform: appeared)
        .safeAreaInset(edge: .bottom) { bottomValue }
    }
    
    var invalidCalculationSection: some View {
        var titleAndMessage: (String, String)? {
            guard let kcal = HealthDetails.Maintenance.Adaptive.calculate(
                interval: interval,
                weightChange: weightChange,
                dietaryEnergy: dietaryEnergy
            ) else { return nil }
            return switch kcal {
            case _ where kcal < 0:
                ("Dietary Energy Too Low", "Your weight gain far exceeds the dietary energy, making the calculation unrealistic.\n\nPlease make sure you have accounted for all the dietary energy you consumed to make a realistic calculation.")
            case _ where kcal < MinimumAdaptiveEnergyInKcal:
                ("Dietary Energy Too Low", "The calculated maintenance energy is below the minimum of \(HealthDetails.Maintenance.Adaptive.minimumEnergyString(in: energyUnit)) that we can safely recommend.\n\nPlease make sure you have accounted for all the dietary energy you consumed to make a realistic calculation.")
            default:
                nil
            }
        }
        
        return Group {
            if let (title, message) = titleAndMessage {
                Section {
                    NoticeSection(
                        style: .plain,
                        notice: .init(
                            title: title,
                            message: message,
                            imageName: "exclamationmark.triangle"
                        )
                    )
                }
            }
        }
    }
    
    func appeared() {
        Task {
            await fetchPoints()
        }
    }
    
    func fetchPoints() async {
        await fetchDietaryEnergyPoints()
        await fetchWeightPoints()
        await MainActor.run {
            withAnimation {
                self.adaptiveInKcal = adaptive.kcal
            }
        }
    }
    
    func fetchWeightPoints() async {
        guard weightChange.type == .weights else {
            startWeight = nil
            startWeightMovingAverageWeights = [:]
            endWeight = nil
            endWeightMovingAverageWeights = [:]
            return
        }
        let points = WeightChange.Points(date: date, interval: interval)
        weightChange.points = points
        await fetchStartWeightPoint(points.start)
        await fetchEndWeightPoint(points.end)

        await MainActor.run {
            withAnimation {
                weightChange.kg = if let end = weightChange.points?.end.kg, let start = weightChange.points?.start.kg {
                    end - start
                } else {
                    nil
                }
            }
        }
    }
    
    func fetchStartWeightPoint(_ point: WeightChangePoint) async {
        if let movingAverageInterval = point.movingAverageInterval {

            var weights: [Date : HealthDetails.Weight] = [:]
            for index in 0..<movingAverageInterval.numberOfDays {
                let date = point.date.startOfDay.moveDayBy(-index)
                let weight = await HealthProvider.fetchOrCreateBackendWeight(for: date)
                weights[date] = weight
            }
            
            await MainActor.run { [weights] in
                startWeight = nil
                startWeightMovingAverageWeights = weights
                weightChange.points?.start.kg = weights.values
                    .compactMap { $0.weightInKg }
                    .average
            }

        } else {
            let weight = await HealthProvider.fetchOrCreateBackendWeight(for: point.date)
            await MainActor.run {
                startWeight = weight
                startWeightMovingAverageWeights = [:]
                weightChange.points?.start.kg = weight.weightInKg
            }
        }
    }
    
    func fetchEndWeightPoint(_ point: WeightChangePoint) async {
        if let movingAverageInterval = point.movingAverageInterval {

            var weights: [Date : HealthDetails.Weight] = [:]
            for index in 0..<movingAverageInterval.numberOfDays {
                let date = point.date.startOfDay.moveDayBy(-index)
                let weight = await HealthProvider.fetchOrCreateBackendWeight(for: date)
                if date.isToday {
                    print("Here we go")
                }
                weights[date] = weight
            }
            
            endWeight = nil
            endWeightMovingAverageWeights = weights
            weightChange.points?.end.kg = weights.values
                .compactMap { $0.weightInKg }
                .average

        } else {
            let weight = await HealthProvider.fetchOrCreateBackendWeight(for: point.date)
            endWeight = weight
            endWeightMovingAverageWeights = [:]
            weightChange.points?.end.kg = weight.weightInKg
        }
    }
    
    func fetchDietaryEnergyPoints() async {
        let start = CFAbsoluteTimeGetCurrent()
        print("Fetching points: 🍏")
        var points: [DietaryEnergyPoint] = []
        for index in 0..<interval.numberOfDays {
            let date = date.moveDayBy(-(index + 1))
            
            /// Fetch the point if it exists
            if let point = await HealthProvider.fetchBackendDietaryEnergyPoint(for: date)
            {
                print("Fetched existing point for: \(date.shortDateString)")
                points.append(point)
            }
            /// Otherwise check if we have a value in the log for it and create a point for it if needed
            else if let energyInKcal = await DayProvider.fetchBackendEnergyInKcal(for: date)
            {
                print("No existing point for: \(date.shortDateString) – created one with log value")
                /// Create a `.log` sourced `DietaryEnergyPoint` for this date
                let point = DietaryEnergyPoint(
                    date: date,
                    kcal: energyInKcal,
                    source: .log
                )
                points.append(point)

                /// Set this in the backend too
                HealthProvider.setBackendDietaryEnergyPoint(point, for: date)
            }
            /// Finally, as a fallback—create an exclusionary `DietaryEnergyPoint` for this date
            else
            {
                print("No existing point for: \(date.shortDateString) – created one as `.notCounted`")
                let point = DietaryEnergyPoint(
                    date: date,
                    source: .notCounted
                )
                points.append(point)

                /// Set this in the backend too
                HealthProvider.setBackendDietaryEnergyPoint(point, for: date)
            }
        }
        print("🍏 Took \(CFAbsoluteTimeGetCurrent()-start)s")
        await MainActor.run { [points] in
            self.dietaryEnergyPoints = points
            withAnimation {
                dietaryEnergy = .init(points: points)
            }
        }
    }

    var energyUnit: EnergyUnit { healthProvider.settingsProvider.energyUnit }
    var bodyMassUnit: BodyMassUnit { healthProvider.settingsProvider.bodyMassUnit }
    var energyUnitString: String { healthProvider.settingsProvider.energyUnit.abbreviation }

    var bottomValue: some View {
        var energyValue: Double? {
            guard let adaptiveInKcal else { return nil }
            return EnergyUnit.kcal.convert(adaptiveInKcal, to: energyUnit)
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
            doubleUnitString: energyUnitString
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

    var weightChangeLink: some View {
        var weightChangeValue: Double? {
            guard let kg = weightChange.kg else { return nil }
            return BodyMassUnit.kg.convert(kg, to: bodyMassUnit)
        }
        
        return Section {
            NavigationLink {
                WeightChangeForm(
                    date: date,
                    weightChange: weightChange,
                    startWeight: $startWeight,
                    startWeightMovingAverageWeights: $startWeightMovingAverageWeights,
                    endWeight: $endWeight,
                    endWeightMovingAverageWeights: $endWeightMovingAverageWeights,
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    saveHandler: { weightChange, shouldResync in
                        self.weightChange = weightChange
                        handleChanges(shouldResync)
                    }
                )
            } label: {
                HStack {
                    Text("Weight Change")
                    Spacer()
                    if let weightChangeValue {
                        HStack(spacing: 5) {
                            Text("\(weightChangeValue > 0 ? "+" : "")\(weightChangeValue.cleanHealth)")
                                .contentTransition(.numericText(value: weightChangeValue))
                            Text(bodyMassUnit.abbreviation)
                        }
                    } else {
                        Text(NotSetString)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    var dietaryEnergyLink: some View {
        
        var dailyAverageValue: Double? {
            guard let kcal = dietaryEnergy.kcalPerDay else { return nil }
            return EnergyUnit.kcal.convert(kcal, to: energyUnit)
        }
        
        return Section {
            NavigationLink {
                DietaryEnergyForm(
                    date: date,
                    dietaryEnergy: dietaryEnergy,
                    points: $dietaryEnergyPoints,
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    saveHandler: { dietaryEnergy in
                        self.dietaryEnergy = dietaryEnergy
                        handleChanges()
                    }
                )
            } label: {
                HStack {
                    Text("Dietary Energy")
                    Spacer()
                    if let dailyAverageValue {
                        HStack(spacing: 5) {
                            Text("\(dailyAverageValue.formattedEnergy)")
                                .contentTransition(.numericText(value: dailyAverageValue))
                            Text("\(energyUnitString) / day")
                        }
                    } else {
                        Text(NotSetString)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    var intervalSection: some View {
        let weeksBinding = Binding<Int>(
            get: { interval.weeks ?? 1 },
            set: { newValue in
                withAnimation {
                    interval.weeks = newValue
                }
                handleChanges()
            }
        )
        
        let weeks = weeksBinding.wrappedValue

        return Section("Use Data from past") {
            HStack(spacing: 5) {
                Stepper(
                    "",
                    value: weeksBinding,
                    in: 1...MaxAdaptiveWeeks
                )
                .fixedSize()
                Spacer()
                Text("\(weeks)")
                    .contentTransition(.numericText(value: Double(weeks)))
                Text("week\(weeks > 1 ? "s" : "")")
            }
            .foregroundStyle(.primary)
        }
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresented = false
                } label: {
                    CloseButtonLabel()
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Maintenance Energy")
                    .font(.headline)
            }
        }
    }

    func save(_ shouldResync: Bool) {
        saveHandler(adaptive, shouldResync)
    }
    
    var adaptive: HealthDetails.Maintenance.Adaptive {
        .init(
            kcal: adaptiveInKcal,
            interval: interval,
            dietaryEnergyPoints: dietaryEnergyPoints,
            weightChange: weightChange
        )
    }
    
    func handleChanges(_ shouldResync: Bool = false) {
        Task {
            await fetchPoints()
            save(shouldResync)
        }
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
            VStack(alignment: .leading) {
//                Text("Your Adaptive Maintenance is a calculation of your maintenance energy using the energy balance equation.\n\nThe dietary energy you had consumed over a specified period and the resulting change in your weight is used to determine the average daily energy consumption that would have resulted in a net zero change in weight, ie. your maintenance.")
                Text("Your Adaptive Maintenance is a calculation of your maintenance energy using the energy balance equation.\n\nThe change in your weight over a specified period is compared to the dietary energy you consumed to determine the what your true maintenance is—ie. the average daily energy you would have had to consume to have no change in weight.")
            }
        }
    }
}

#Preview("DemoView") {
    DemoView()
}
