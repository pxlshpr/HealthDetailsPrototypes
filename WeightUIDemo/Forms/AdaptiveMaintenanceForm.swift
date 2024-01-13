import SwiftUI
import SwiftSugar
import PrepShared

struct AdaptiveMaintenanceForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    @Bindable var healthProvider: HealthProvider

    let date: Date
    let initialAdaptive: HealthDetails.Maintenance.Adaptive
    
    @State var adaptiveInKcal: Double?
    @State var interval: HealthInterval
    @State var dietaryEnergy: HealthDetails.Maintenance.Adaptive.DietaryEnergy
    @State var weightChange: WeightChange
    
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    let saveHandler: (HealthDetails.Maintenance.Adaptive) -> ()
    
    @State var showingInfo = false

    init(
        date: Date = Date.now,
        adaptive: HealthDetails.Maintenance.Adaptive,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false),
        saveHandler: @escaping (HealthDetails.Maintenance.Adaptive) -> ()
    ) {
        self.date = date
        self.initialAdaptive = adaptive
        self.healthProvider = healthProvider
        self.saveHandler = saveHandler
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: date.isToday)
        
        _adaptiveInKcal = State(initialValue: adaptive.kcal)
        _interval = State(initialValue: adaptive.interval)
        _dietaryEnergy = State(initialValue: adaptive.dietaryEnergy)
        _weightChange = State(initialValue: adaptive.weightChange)
    }

    var body: some View {
        Form {
            notice
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
        .navigationBarBackButtonHidden(isLegacy && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    func setDismissDisabled() {
        dismissDisabled = isLegacy && isEditing && isDirty
    }

    var bottomValue: some View {
        var energyValue: Double? {
            guard let adaptiveInKcal else { return nil }
            return EnergyUnit.kcal.convert(adaptiveInKcal, to: settingsProvider.energyUnit)
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
            doubleUnitString: settingsProvider.energyUnit.abbreviation
        )
    }
    
    @ViewBuilder
    var notice: some View {
        if isLegacy {
            NoticeSection.legacy(date, isEditing: $isEditing)
        }
    }

    var weightChangeLink: some View {
        var weightChangeValue: Double? {
            guard let kg = weightChange.kg else { return nil }
            return BodyMassUnit.kg.convert(kg, to: settingsProvider.bodyMassUnit)
        }
        
        return Section {
            NavigationLink {
                WeightChangeForm(
                    date: date,
                    weightChange: weightChange,
                    healthProvider: healthProvider,
                    settingsProvider: settingsProvider,
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled,
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
                        Text("\(weightChangeValue.cleanHealth) \(settingsProvider.bodyMassUnit.abbreviation)")
                    } else {
                        Text("Not Set")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isLegacy && isEditing)
        }
    }

    var dietaryEnergyLink: some View {
        
        var dailyAverageValue: Double? {
            guard let kcal = dietaryEnergy.kcalPerDay else { return nil }
            return EnergyUnit.kcal.convert(kcal, to: settingsProvider.energyUnit)
        }
        
        return Section {
            NavigationLink {
                DietaryEnergyForm(
                    date: date,
                    dietaryEnergy: dietaryEnergy,
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled,
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
                        Text("\(dailyAverageValue.formattedEnergy) \(settingsProvider.energyUnit.abbreviation) / day")
                    } else {
                        Text("Not Set")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isLegacy && isEditing)
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
            .foregroundStyle(isEditing ? .primary : .secondary)
            .disabled(!isEditing)
        }
    }
    
    var isLegacy: Bool {
        date.startOfDay < Date.now.startOfDay
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
            ToolbarItem(placement: .principal) {
                Text("Maintenance Energy")
                    .font(.headline)
            }
        }
    }

    func save() {
        saveHandler(adaptive)
    }
    
    func undo() {
        adaptiveInKcal = initialAdaptive.kcal
        interval = initialAdaptive.interval
        dietaryEnergy = initialAdaptive.dietaryEnergy
        weightChange = initialAdaptive.weightChange
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
        setIsDirty()
        if !isLegacy {
            save()
        }
    }
    
    func setIsDirty() {
        isDirty = adaptive != initialAdaptive
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
            VStack(alignment: .leading) {
                Text("Your Adaptive Maintenance is a calculation of your maintenance energy using the energy balance equation.\n\nThe dietary energy you had consumed over a specified period and the resulting change in your weight is used to determine the average daily energy consumption that would have resulted in a net zero change in weight, ie. your maintenance.")
            }
        }
    }
}

//#Preview("Current") {
//    NavigationView {
//        AdaptiveMaintenanceForm()
//    }
//}
//
//#Preview("Past") {
//    NavigationView {
//        AdaptiveMaintenanceForm(date: MockPastDate)
//    }
//}

//struct DismissTest: View {
//    @State var presented: Bool = false
//    var body: some View {
//        NavigationView {
//            Form {
//                Button("Present") {
//                    presented = true
//                }
//            }
//            .sheet(isPresented: $presented) {
//                NavigationView {
//                    AdaptiveMaintenanceForm(
//                        date: MockPastDate,
//                        isPresented: $presented
//                    )
//                }
//            }
//        }
//    }
//}
//
//#Preview("Dismiss Test") {
//    DismissTest()
//}

#Preview("DemoView") {
    DemoView()
}
