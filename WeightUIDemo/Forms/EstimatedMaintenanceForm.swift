import SwiftUI
import PrepShared

struct EstimatedMaintenanceForm: View {

    @Bindable var healthProvider: HealthProvider
    @Binding var isPresented: Bool

    let date: Date
    
    @State var estimateInKcal: Double? = nil
    @State var restingEnergy: HealthDetails.Maintenance.Estimate.RestingEnergy
    @State var activeEnergy: HealthDetails.Maintenance.Estimate.ActiveEnergy
    
    let saveHandler: (HealthDetails.Maintenance.Estimate, Bool) -> ()

    init(
        date: Date,
        estimate: HealthDetails.Maintenance.Estimate,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        saveHandler: @escaping (HealthDetails.Maintenance.Estimate, Bool) -> ()
    ) {
        self.date = date
        self.healthProvider = healthProvider
        self.saveHandler = saveHandler
        _isPresented = isPresented
        
        _restingEnergy = State(initialValue: estimate.restingEnergy)
        _activeEnergy = State(initialValue: estimate.activeEnergy)
        _estimateInKcal = State(initialValue: estimate.kcal)
    }
    
    var body: some View {
        Form {
            dateSection
            restingEnergyLink
            activeEnergyLink
            explanation
        }
        .navigationTitle("Estimated")
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) { bottomValue }
    }
    
    var energyUnit: EnergyUnit { healthProvider.settingsProvider.energyUnit }
    
    var bottomValue: some View {
        var energyValue: Double? {
            guard let estimateInKcal else { return nil }
            return EnergyUnit.kcal.convert(estimateInKcal, to: energyUnit)
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
    
    var estimate: HealthDetails.Maintenance.Estimate {
        .init(
            kcal: estimateInKcal,
            restingEnergy: restingEnergy,
            activeEnergy: activeEnergy
        )
    }
    
    func handleChanges(_ shouldResync: Bool = false) {
        let estimateInKcal: Double? = if let restingEnergyInKcal = restingEnergy.kcal, let activeEnergyInKcal = activeEnergy.kcal {
            restingEnergyInKcal + activeEnergyInKcal
        } else {
            nil
        }
        self.estimateInKcal = estimateInKcal
        save(shouldResync)
    }
    
    func save(_ shouldResync: Bool) {
        saveHandler(estimate, shouldResync)
    }
    
    func saveRestingEnergy(_ restingEnergy: HealthDetails.Maintenance.Estimate.RestingEnergy, shouldResync: Bool) {
        self.restingEnergy = restingEnergy
        handleChanges(shouldResync)
    }

    func saveActiveEnergy(_ activeEnergy: HealthDetails.Maintenance.Estimate.ActiveEnergy, shouldResync: Bool) {
        self.activeEnergy = activeEnergy
        handleChanges(shouldResync)
    }

    var restingEnergyLink: some View {
        var energyValue: Double? {
            guard let kcal = restingEnergy.kcal else { return nil }
            return EnergyUnit.kcal.convert(kcal, to: energyUnit)
        }
        
        return Section {
            NavigationLink {
                RestingEnergyForm(
                    date: date,
                    restingEnergy: restingEnergy,
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    saveHandler: saveRestingEnergy
                )
            } label: {
                HStack {
                    Text("Resting Energy")
                    Spacer()
                    if let energyValue {
                        HStack {
                            Text("\(energyValue.formattedEnergy)")
                                .contentTransition(.numericText(value: energyValue))
                            Text(energyUnitString)
                        }
                    } else {
                        Text(NotSetString)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    var energyUnitString: String { energyUnit.abbreviation }

    var activeEnergyLink: some View {
        var energyValue: Double? {
            guard let kcal = activeEnergy.kcal else { return nil }
            return EnergyUnit.kcal.convert(kcal, to: energyUnit)
        }

        return Section {
            NavigationLink {
                ActiveEnergyForm(
                    date: date,
                    activeEnergy: activeEnergy,
                    restingEnergyInKcal: restingEnergy.kcal,
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    saveHandler: saveActiveEnergy
                )
            } label: {
                HStack {
                    Text("Active Energy")
                    Spacer()
                    if let energyValue {
                        HStack {
                            Text("\(energyValue.formattedEnergy)")
                                .contentTransition(.numericText(value: energyValue))
                            Text(energyUnitString)
                        }
                    } else {
                        Text(NotSetString)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("This is an estimate of your maintenance energy, which is calculated by adding together your Resting and Active Energy components.\n\nYour Resting Energy is the energy your body uses each day while minimally active. Your active energy is the energy burnt over and above your Resting Energy use.")
            }
        }
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
}

#Preview("Demo") {
    DemoView()
}
