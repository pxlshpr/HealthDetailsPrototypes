import SwiftUI

struct EstimatedMaintenanceForm: View {

    @State var value: Double? = 2782
    
    let pastDate: Date?
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool

    init(
        pastDate: Date? = nil,
        isPresented: Binding<Bool> = .constant(true)
    ) {
        self.pastDate = pastDate
        _isPresented = isPresented
        _isEditing = State(initialValue: true)
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
            value: $value,
            valueString: Binding<String?>(
                get: { value?.formattedEnergy },
                set: { _ in }
            ),
            isDisabled: Binding<Bool>(
                get: { isEditing && isPast },
                set: { _ in }
            ),
            unitString: "kcal"
        )
    }
    
    var restingEnergyLink: some View {
        Section {
            NavigationLink {
                RestingEnergyForm(
                    pastDate: pastDate,
                    isPresented: $isPresented
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
                ActiveEnergyForm(pastDate: pastDate, isPresented: $isPresented)
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
                Button("Done") {
                    isPresented = false
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

#Preview("Current") {
    NavigationView {
        EstimatedMaintenanceForm()
    }
}

#Preview("Past") {
    NavigationView {
        EstimatedMaintenanceForm(pastDate: MockPastDate)
    }
}
