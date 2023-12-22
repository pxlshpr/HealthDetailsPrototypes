import SwiftUI
import SwiftSugar

struct MaintenanceForm: View {
    
    @Environment(\.dismiss) var dismiss

    @State var hasAppeared = false
    @State var maintenancetype: MaintenanceType = .adaptive
    @State var value: Double = 3225
    @State var adaptiveValue: Double = 3225
    @State var estimatedValue: Double = 2856

    var body: some View {
        NavigationStack {
            Group {
                if hasAppeared {
                    Form {
                        valuePicker
                        adaptiveLink
                        estimatedLink
                        explanation
                    }
                } else {
                    Color.clear
                }
            }
            .navigationTitle("Maintenance Energy")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                hasAppeared = true
            }
        }
    }
    
    var adaptiveLink: some View {
        Section {
            NavigationLink {
                AdaptiveMaintenanceForm()
            } label: {
                HStack {
                    Text("Adaptive")
                    Spacer()
                    Text("\(adaptiveValue.formattedEnergy) kcal")
                }
            }
        }
    }

    var estimatedLink: some View {
        Section {
            NavigationLink {
                
            } label: {
                HStack {
                    Text("Estimated")
                    Spacer()
                    Text("\(estimatedValue.formattedEnergy) kcal")
                }
            }
        }
    }

    var valuePicker: some View {
        let binding = Binding<MaintenanceType>(
            get: { maintenancetype },
            set: { newValue in
                withAnimation {
                    maintenancetype = newValue
                    value = maintenancetype == .adaptive ? adaptiveValue : estimatedValue
                }
            }
        )
        return Section("Use") {
            Picker("", selection: binding) {
                ForEach(MaintenanceType.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.segmented)
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
        }
    }

    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Your maintenance energy (also known as your Total Daily Energy Expenditure or TDEE) is the dietary energy you would need to consume daily to maintain your weight.\n\nIt may be used when creating energy goals that target a desired change in your weight.\n\nYou can choose to calculate it in two ways:")
                Label {
                    Text("\"Adaptive\" compares your weight change to the energy you consumed over a specified period.")
                } icon: {
                    Circle()
                        .foregroundStyle(Color(.label))
                        .frame(width: 5, height: 5)
                }
                Label {
                    Text("\"Estimated\" estimates and totals your daily resting and active energies.")
                } icon: {
                    Circle()
                        .foregroundStyle(Color(.label))
                        .frame(width: 5, height: 5)
                }
                Text("\nThe adaptive calculation be more accurate in most cases as it takes into account trends over time.")
                /// You would find the adaptive calculation to be more accurate, especially when you have enough data.
            }
        }
    }
}

#Preview {
    MaintenanceForm()
}
