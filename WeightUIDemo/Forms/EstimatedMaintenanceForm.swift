import SwiftUI
import PrepShared

struct EstimatedMaintenanceForm: View {

    @Environment(SettingsProvider.self) var settingsProvider
    @Bindable var healthProvider: HealthProvider
    
    let date: Date
    @State var estimatedMaintenanceInKcal: Double? = nil
    @State var restingEnergyInKcal: Double? = nil
    @State var activeEnergyInKcal: Double? = nil
    
    @State var isEditing: Bool
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    @State var showingRestingEnergyForm = false
    @State var showingActiveEnergyForm = false
    
    init(
        date: Date,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.date = date
        self.healthProvider = healthProvider
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: true)
        
        _restingEnergyInKcal = State(initialValue: healthProvider
            .healthDetails.maintenance.estimate.restingEnergy.kcal
        )
        _activeEnergyInKcal = State(initialValue: healthProvider
            .healthDetails.maintenance.estimate.activeEnergy.kcal
        )
        _estimatedMaintenanceInKcal = State(initialValue: healthProvider
            .healthDetails.maintenance.estimate.kcal
        )
    }
    
    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
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
        .onChange(of: showingRestingEnergyForm) { oldValue, newValue in
            if !newValue {
                updateValues()
            }
        }
        .onChange(of: showingActiveEnergyForm) { oldValue, newValue in
            if !newValue {
                updateValues()
            }
        }
    }
    
    func updateValues() {
        withAnimation {
            self.restingEnergyInKcal = healthProvider.healthDetails.maintenance.estimate.restingEnergy.kcal
            self.activeEnergyInKcal = healthProvider.healthDetails.maintenance.estimate.activeEnergy.kcal
            self.estimatedMaintenanceInKcal = healthProvider.healthDetails.maintenance.kcal
        }
    }
    
    var bottomValue: some View {
        MeasurementBottomBar(
            double: $estimatedMaintenanceInKcal,
            doubleString: Binding<String?>(
                get: { estimatedMaintenanceInKcal?.formattedEnergy },
                set: { _ in }
            ),
            doubleUnitString: "kcal",
            isDisabled: Binding<Bool>(
                get: { isEditing && isLegacy },
                set: { _ in }
            )
        )
    }
    
    var restingEnergyLink: some View {
        var energyValue: Double? {
            guard let restingEnergyInKcal else { return nil }
            return EnergyUnit.kcal.convert(restingEnergyInKcal, to: settingsProvider.energyUnit)
        }
        
        func saveRestingEnergy(_ restingEnergy: HealthDetails.Maintenance.Estimate.RestingEnergy) {
            if isLegacy {
                //TODO: Save resting energy for legacy date here
            } else {
                healthProvider.saveRestingEnergy(restingEnergy)
            }
        }
        
        return Section {
            HStack {
                Text("Resting Energy")
                Spacer()
                if let energyValue {
                    Text("\(energyValue.formattedEnergy) \(settingsProvider.energyUnit.abbreviation)")
                } else {
                    Text("Not Set")
                        .foregroundStyle(.secondary)
                }
                Button {
                    showingRestingEnergyForm = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingRestingEnergyForm) {
            NavigationView {
                RestingEnergyForm(
                    date: date,
                    settingsProvider: settingsProvider,
                    healthProvider: healthProvider,
                    dismissDisabled: $dismissDisabled,
                    save: saveRestingEnergy
                )
            }
        }
    }

    var activeEnergyLink: some View {
        var energyValue: Double? {
            guard let activeEnergyInKcal else { return nil }
            return EnergyUnit.kcal.convert(activeEnergyInKcal, to: settingsProvider.energyUnit)
        }

        return Section {
            HStack {
                Text("Active Energy")
                Spacer()
                if let energyValue {
                    Text("\(energyValue.formattedEnergy) \(settingsProvider.energyUnit.abbreviation)")
                } else {
                    Text("Not Set")
                        .foregroundStyle(.secondary)
                }
                Button {
                    showingActiveEnergyForm = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingActiveEnergyForm) {
            NavigationView {
                ActiveEnergyForm(
                    pastDate: date,
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled
                )
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
