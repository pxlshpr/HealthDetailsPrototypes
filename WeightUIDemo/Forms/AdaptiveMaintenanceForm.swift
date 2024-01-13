import SwiftUI
import SwiftSugar
import PrepShared

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
        .sheet(isPresented: $showingInfo) {
            AdaptiveMaintenanceInfo(interval: $interval)
        }
        .safeAreaInset(edge: .bottom) { bottomValue }
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
                        Text("Not Set")
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
                        Text("Not Set")
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
                    in: 1...2
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
            dietaryEnergy: dietaryEnergy,
            weightChange: weightChange
        )
    }
    
    func handleChanges() {
        save()
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
