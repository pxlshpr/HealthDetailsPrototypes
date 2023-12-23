import SwiftUI
import SwiftSugar

struct MaintenanceForm: View {
    
    @Environment(\.dismiss) var dismiss

    @State var hasAppeared = false
    @State var maintenancetype: MaintenanceType = .adaptive
    @State var value: Double = 3225
    @State var adaptiveValue: Double = 3225
    @State var estimatedValue: Double = 2856

    @State var showingMaintenanceInfo = false
    
    var body: some View {
        NavigationStack {
//            Group {
//                if hasAppeared {
                    Form {
                        explanation
                        valuePicker
                        adaptiveLink
                        estimatedLink
                    }
                    .padding(.top, 0.3) /// Navigation Bar Fix
//                } else {
//                    Color.clear
//                }
//            }
            .navigationTitle("Maintenance Energy")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
        }
        .sheet(isPresented: $showingMaintenanceInfo) {
            MaintenanceInfo()
        }
//        .onAppear {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//                hasAppeared = true
//            }
//        }
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
                EstimatedMaintenanceForm()
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
        var footer: some View {
            Button {
                showingMaintenanceInfo = true
            } label: {
                Text("Learn more…")
                    .font(.footnote)
            }
        }
        return Section(footer: footer) {
            Text("Your Maintenance Energy (also known as your Total Daily Energy Expenditure or TDEE) is the dietary energy you would need to consume daily to maintain your weight.\n\nIt may be used when creating energy goals that target a desired change in your weight.")
        }
    }
}

#Preview {
    MaintenanceForm()
}
