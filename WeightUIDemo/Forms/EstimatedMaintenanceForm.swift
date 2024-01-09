import SwiftUI
import PrepShared

struct EstimatedMaintenanceForm: View {

    @Environment(SettingsProvider.self) var settingsProvider
    @Bindable var healthProvider: HealthProvider
    
    let date: Date
    let initialEstimate: HealthDetails.Maintenance.Estimate
    
    @State var estimateInKcal: Double? = nil
    @State var restingEnergy: HealthDetails.Maintenance.Estimate.RestingEnergy
    @State var activeEnergy: HealthDetails.Maintenance.Estimate.ActiveEnergy
    
    @State var isEditing: Bool
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    let saveHandler: (HealthDetails.Maintenance.Estimate) -> ()

    init(
        date: Date,
        estimate: HealthDetails.Maintenance.Estimate,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false),
        saveHandler: @escaping (HealthDetails.Maintenance.Estimate) -> ()
    ) {
        self.date = date
        self.initialEstimate = estimate
        self.healthProvider = healthProvider
        self.saveHandler = saveHandler
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: true)
        
        _restingEnergy = State(initialValue: estimate.restingEnergy)
        _activeEnergy = State(initialValue: estimate.activeEnergy)
        _estimateInKcal = State(initialValue: estimate.kcal)
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
        var energyValue: Double? {
            guard let estimateInKcal else { return nil }
            return EnergyUnit.kcal.convert(estimateInKcal, to: settingsProvider.energyUnit)
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
            doubleUnitString: energyUnitString,
            isDisabled: Binding<Bool>(
                get: {
                    //TODO: Test this, as it's probably wrong
                    isEditing && isLegacy
                },
                set: { _ in }
            )
        )
    }
    
    var estimate: HealthDetails.Maintenance.Estimate {
        .init(
            kcal: estimateInKcal,
            restingEnergy: restingEnergy,
            activeEnergy: activeEnergy
        )
    }
    
    func handleChanges() {
        let estimateInKcal: Double? = if let restingEnergyInKcal = restingEnergy.kcal, let activeEnergyInKcal = activeEnergy.kcal {
            restingEnergyInKcal + activeEnergyInKcal
        } else {
            nil
        }
        self.estimateInKcal = estimateInKcal
        save()
    }
    
    func save() {
        saveHandler(estimate)
    }
    
    func saveRestingEnergy(_ restingEnergy: HealthDetails.Maintenance.Estimate.RestingEnergy) {
        self.restingEnergy = restingEnergy
        handleChanges()
    }

    func saveActiveEnergy(_ activeEnergy: HealthDetails.Maintenance.Estimate.ActiveEnergy) {
        self.activeEnergy = activeEnergy
        handleChanges()
    }

    var restingEnergyLink: some View {
        var energyValue: Double? {
            guard let kcal = restingEnergy.kcal else { return nil }
            return EnergyUnit.kcal.convert(kcal, to: settingsProvider.energyUnit)
        }
        
        return Section {
            NavigationLink {
                RestingEnergyForm(
                    date: date,
                    restingEnergy: restingEnergy,
                    settingsProvider: settingsProvider,
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled,
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
            guard let kcal = activeEnergy.kcal else { return nil }
            return EnergyUnit.kcal.convert(kcal, to: settingsProvider.energyUnit)
        }

        return Section {
            NavigationLink {
                ActiveEnergyForm(
                    date: date,
                    activeEnergy: activeEnergy,
                    restingEnergyInKcal: restingEnergy.kcal,
                    settingsProvider: settingsProvider,
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled,
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

//#Preview("Current") {
//    NavigationView {
//        EstimatedMaintenanceForm(healthProvider: MockCurrentProvider)
//    }
//}
//
//#Preview("Past") {
//    NavigationView {
//        EstimatedMaintenanceForm(healthProvider: MockPastProvider)
//    }
//}

#Preview("Demo") {
    DemoView()
}
