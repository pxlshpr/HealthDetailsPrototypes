import SwiftUI

struct EstimatedMaintenanceForm: View {

    @Environment(\.dismiss) var dismiss

    @State var value: Double = 2782
    
    var body: some View {
        Form {
            explanation
            restingEnergyLink
            activeEnergyLink
        }
        .navigationTitle("Estimated")
        .toolbar { toolbarContent }
        .navigationDestination(for: Route.self) { route in
            switch route {
            case .resting:  RestingEnergyForm()
            case .active:   ActiveEnergyForm()
            }
        }
    }
    
    enum Route {
        case resting
        case active
    }
    
    var restingEnergyLink: some View {
        Section {
            NavigationLink(value: Route.resting) {
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
            NavigationLink(value: Route.active) {
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
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .bottomBar) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Spacer()
                    Text("\(value.formattedEnergy)")
                        .contentTransition(.numericText(value: value))
                        .font(LargeNumberFont)
                    Text("kcal")
                        .font(LargeUnitFont)
                        .foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
            ToolbarItem(placement: .principal) {
                Text("Maintenance Energy")
                    .font(.headline)
            }
        }
    }

}

#Preview {
    EstimatedMaintenanceForm()
}
