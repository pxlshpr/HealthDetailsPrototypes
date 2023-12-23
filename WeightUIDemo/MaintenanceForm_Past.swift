import SwiftUI
import SwiftSugar

struct MaintenanceForm_Past: View {
    
    @Environment(\.dismiss) var dismiss

    @State var hasAppeared = false
    @State var maintenancetype: MaintenanceType = .adaptive
    @State var value: Double = 3225
    @State var adaptiveValue: Double = 3225
    @State var estimatedValue: Double = 2856

    @State var isEditing = false

    var body: some View {
        NavigationStack {
            Group {
                if hasAppeared {
                    Form {
                        if !isEditing {
                            notice
                        }
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
    
    var controlColor: Color {
        isEditing ? Color(.label) : Color(.secondaryLabel)
    }

    var notice: some View {
        NoticeSection(
            style: .plain,
            title: "Previous Data",
            message: "This data has been preserved to ensure any goals set on this day remain unchanged.",
            image: {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 30))
                    .padding(5)
            }
        )
    }
    
    var adaptiveLink: some View {
        Section {
            NavigationLink {
                AdaptiveMaintenanceForm_Past()
            } label: {
                HStack {
                    Text("Adaptive")
                    Spacer()
                    Text("\(adaptiveValue.formattedEnergy) kcal")
                }
            }
            .disabled(isEditing)
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
            .disabled(isEditing)
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
            .disabled(!isEditing)
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
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        withAnimation {
                            isEditing = false
                        }
                    } else {
                        withAnimation {
                            isEditing = true
                        }
                    }
                }
                .fontWeight(.semibold)
            }
            ToolbarItem(placement: .topBarLeading) {
                if isEditing {
                    Button("Cancel") {
                        withAnimation {
                            isEditing = false
                        }
                    }
                }
            }
        }
    }

    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Your maintenance energy (also known as your Total Daily Energy Expenditure or TDEE) is the dietary energy you would need to consume daily to maintain your weight.\n\nIt may be used when creating energy goals that target a desired change in your weight.\n\nYou can choose to calculate it in two ways:")
                dotPoint("\"Adaptive\" compares your weight change to the energy you consumed over a specified period.")
                dotPoint("\"Estimated\" estimates and totals your daily resting and active energies.")
                Text("\nThe adaptive calculation be more accurate in most cases as it takes into account trends over time.")
                /// You would find the adaptive calculation to be more accurate, especially when you have enough data.
            }
        }
    }
}

#Preview {
    MaintenanceForm_Past()
}
