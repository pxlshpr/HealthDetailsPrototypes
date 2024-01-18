import SwiftUI
import SwiftSugar
import PrepShared

let MaxAdaptiveWeeks: Int = 2

struct AdaptiveMaintenanceForm: View {
    
    @Bindable var healthProvider: HealthProvider
    @Binding var isPresented: Bool

    let date: Date
    
    @State var adaptiveInKcal: Double?
    @State var interval: HealthInterval
    @State var dietaryEnergy: HealthDetails.Maintenance.Adaptive.DietaryEnergy
    @State var weightChange: WeightChange
    
    let saveHandler: (HealthDetails.Maintenance.Adaptive) -> ()
    
    @State var showingInfo = false

    @State var dietaryEnergyPoints: [DietaryEnergyPoint] = []
    
    init(
        date: Date = Date.now,
        adaptive: HealthDetails.Maintenance.Adaptive,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        saveHandler: @escaping (HealthDetails.Maintenance.Adaptive) -> ()
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
            explanation
        }
        .navigationTitle("Adaptive")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingInfo) { AdaptiveMaintenanceInfo(interval: $interval) }
        .onAppear(perform: appeared)
        .safeAreaInset(edge: .bottom) { bottomValue }
    }
    
    
    func appeared() {
        Task {
            await fetchPoints()
        }
    }
    
    func fetchPoints() async {
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
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    saveHandler: { weightChange in
                        self.weightChange = weightChange
                        handleChanges()
                    }
                )
            } label: {
                HStack {
                    Text("Weight Change")
                    Spacer()
                    if let weightChangeValue {
                        Text("\(weightChangeValue.cleanHealth) \(bodyMassUnit.abbreviation)")
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
                        Text("\(dailyAverageValue.formattedEnergy) \(energyUnitString) / day")
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
            HStack(spacing: 3) {
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

    func save() {
        saveHandler(adaptive)
    }
    
    var adaptive: HealthDetails.Maintenance.Adaptive {
        .init(
            kcal: adaptiveInKcal,
            interval: interval,
            dietaryEnergyPoints: dietaryEnergyPoints,
            weightChange: weightChange
        )
    }
    
    func handleChanges() {
        Task {
            await fetchPoints()
            save()
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
