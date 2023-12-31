import SwiftUI

struct EstimatedMaintenanceForm: View {

    @Bindable var healthProvider: HealthProvider
    @State var value: Double? = 2782
    
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
        BottomValue(
            double: $value,
            doubleString: Binding<String?>(
                get: { value?.formattedEnergy },
                set: { _ in }
            ),
            doubleUnitString: "kcal",
            isDisabled: Binding<Bool>(
                get: { isEditing && isPast },
                set: { _ in }
            )
        )
    }
    
    var restingEnergyLink: some View {
        Section {
            NavigationLink {
                RestingEnergyForm(
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled
                )
            } label: {
                HStack {
                    Text("Resting Energy")
                    Spacer()
                    Text("2,021 kcal")
                }
            }
        }
    }

    var activeEnergyLink: some View {
        Section {
            NavigationLink {
                ActiveEnergyForm(
                    pastDate: pastDate,
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled
                )
            } label: {
                HStack {
                    Text("Active Energy")
                    Spacer()
                    Text("761 kcal")
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
