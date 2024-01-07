import SwiftUI
import PrepShared

struct EstimatedMaintenanceForm: View {

    @Environment(SettingsProvider.self) var settingsProvider
    @Bindable var healthProvider: HealthProvider
    
    let date: Date
    let estimate: HealthDetails.Maintenance.Estimate
    
    @State var estimateInKcal: Double? = nil
    @State var restingEnergyInKcal: Double? = nil
    @State var activeEnergyInKcal: Double? = nil
    
    @State var isEditing: Bool
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    init(
        date: Date,
        estimate: HealthDetails.Maintenance.Estimate,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.date = date
        self.estimate = estimate
        self.healthProvider = healthProvider
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: true)
        
        _restingEnergyInKcal = State(initialValue: estimate.restingEnergy.kcal)
        _activeEnergyInKcal = State(initialValue: estimate.activeEnergy.kcal)
        _estimateInKcal = State(initialValue: estimate.kcal)
    }
    
    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            estimate: healthProvider.healthDetails.maintenance.estimate,
            healthProvider: healthProvider,
            isPresented: isPresented,
            dismissDisabled: dismissDisabled
        )
    }

    var body: some View {
        Form {
            notice
            restingEnergyLink
            activeEnergyLink
            explanation
        }
        .navigationTitle("Estimated")
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) { bottomValue }
    }
    
    var bottomValue: some View {
        MeasurementBottomBar(
            double: $estimateInKcal,
            doubleString: Binding<String?>(
                get: { estimateInKcal?.formattedEnergy },
                set: { _ in }
            ),
            doubleUnitString: energyUnitString,
            isDisabled: Binding<Bool>(
                get: { isEditing && isLegacy },
                set: { _ in }
            )
        )
    }
    
    func updateEstimate() {
        guard let restingEnergyInKcal, let activeEnergyInKcal else {
            self.estimateInKcal = nil
            return
        }
        self.estimateInKcal = restingEnergyInKcal + activeEnergyInKcal
    }
    
    func saveRestingEnergy(_ restingEnergy: HealthDetails.Maintenance.Estimate.RestingEnergy) {
        self.restingEnergyInKcal = restingEnergy.kcal
        updateEstimate()

        //TODO: When using this via a VariableSection we should pass in another save handler that the VariableSection handles by manually saving for the specific date
        healthProvider.saveRestingEnergy(restingEnergy)
    }
    
    var restingEnergyLink: some View {
        var energyValue: Double? {
            guard let restingEnergyInKcal else { return nil }
            return EnergyUnit.kcal.convert(restingEnergyInKcal, to: settingsProvider.energyUnit)
        }
        
        return Section {
            NavigationLink {
                RestingEnergyForm(
                    date: date,
                    restingEnergy: estimate.restingEnergy,
                    settingsProvider: settingsProvider,
                    healthProvider: healthProvider,
                    dismissDisabled: $dismissDisabled,
                    save: saveRestingEnergy
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
                        Text("Not Set")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    var energyUnitString: String {
        settingsProvider.energyUnit.abbreviation
    }

    var activeEnergyLink: some View {
        var energyValue: Double? {
            guard let activeEnergyInKcal else { return nil }
            return EnergyUnit.kcal.convert(activeEnergyInKcal, to: settingsProvider.energyUnit)
        }

        return Section {
            NavigationLink {
                ActiveEnergyForm(
                    pastDate: date,
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled
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
                        Text("Not Set")
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
    
    var isLegacy: Bool {
        date.startOfDay < Date.now.startOfDay
    }

    @ViewBuilder
    var notice: some View {
        if isLegacy {
            NoticeSection.legacy(date, isEditing: .constant(false))
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
//                Button("Done") {
//                    isPresented = false
//                }
//                .fontWeight(.semibold)
            }
            ToolbarItem(placement: .principal) {
                Text("Maintenance Energy")
                    .font(.headline)
            }
        }
    }

}

#Preview("Current") {
    NavigationView {
        EstimatedMaintenanceForm(healthProvider: MockCurrentProvider)
    }
}

#Preview("Past") {
    NavigationView {
        EstimatedMaintenanceForm(healthProvider: MockPastProvider)
    }
}
