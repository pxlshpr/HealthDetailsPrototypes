import SwiftUI

struct EstimatedMaintenanceForm: View {

    @Bindable var healthProvider: HealthProvider
    @State var estimatedMaintenanceInKcal: Double? = nil
    @State var restingEnergyInKcal: Double? = nil
    @State var activeEnergyInKcal: Double? = nil
    
    @State var isEditing: Bool
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.healthProvider = healthProvider
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: true)
    }

    var pastDate: Date? {
        healthProvider.pastDate
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
            double: $estimatedMaintenanceInKcal,
            doubleString: Binding<String?>(
                get: { estimatedMaintenanceInKcal?.formattedEnergy },
                set: { _ in }
            ),
            doubleUnitString: "kcal",
            isDisabled: Binding<Bool>(
                get: { isEditing && isPast },
                set: { _ in }
            )
        )
    }
    
    @State var showingRestingEnergyForm = false
    @State var showingActiveEnergyForm = false
    
    var restingEnergyLink: some View {
        Section {
            HStack {
                Text("Resting Energy")
                Spacer()
                if let restingEnergyInKcal {
                    Text("\(restingEnergyInKcal.formattedEnergy) kcal")
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
                    healthProvider: healthProvider,
                    restingEnergyInKcal: $restingEnergyInKcal,
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled
                )
            }
        }
    }

    var activeEnergyLink: some View {
        Section {
            HStack {
                Text("Active Energy")
                Spacer()
                if let activeEnergyInKcal {
                    Text("\(activeEnergyInKcal.formattedEnergy) kcal")
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
                    pastDate: pastDate,
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
    
    var isPast: Bool {
        pastDate != nil
    }

    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: .constant(false))
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
