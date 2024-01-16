import SwiftUI

struct NonTemporalVariableLink: View {
    
    @Bindable var healthProvider: HealthProvider

    let subject: VariablesSections.Subject
    let characteristic: HealthDetail
    let date: Date
    @Binding var isPresented: Bool

    var body: some View {
        NavigationLink {
            form
        } label: {
            label
        }
    }
    
    @ViewBuilder
    var form: some View {
        switch characteristic {
        case .age:
            AgeForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        case .biologicalSex:
            BiologicalSexForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        case .smokingStatus:
            SmokingStatusForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        case .maintenance:
            MaintenanceForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        default:
            EmptyView()
        }
    }
    
    var label: some View {
        HStack {
            Text(characteristic.name)
            Spacer()
            Text(healthProvider.healthDetails.valueString(for: characteristic, healthProvider.settingsProvider))
                .foregroundStyle(healthProvider.healthDetails.hasSet(characteristic) ? .primary : .secondary)
        }
    }
}
