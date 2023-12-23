import SwiftUI

struct HealthIntervalInfo: View {
    
    @Environment(\.dismiss) var dismiss
    @State var hasAppeared = false
    
    let isRestingEnergy: Bool

    var body: some View {
        NavigationStack {
            Group {
                if hasAppeared {
                    form
                } else {
                    Color.clear
                }
            }
            .navigationTitle("Health App Data")
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: appeared)
            .toolbar { toolbarContent }
        }
    }
    
    func appeared() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            hasAppeared = true
        }
    }
    
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Done") {
                dismiss()
            }
            .fontWeight(.semibold)
        }
    }
    
    var form: some View {
        Form {
            Section {
                Text("Your \(isRestingEnergy ? "Resting" : "Active") Energy data can be read from Apple Health in three ways.")
            }
            section("Daily Average", "Uses the daily average of of the specified number of days leading up to the date.")
            section("Same Day", "Uses the data for the current day. Use this if you want your goals to reflect how active you are throughout the day. Keep in mind that this value will keep increasing until the day is over.")
            section("Previous Day", "Uses the data for the previous day. Use this if you want your goals to reflect how active you were the day before.")
        }
    }
    
    func section(_ title: String, _ description: String) -> some View {
        var header: some View {
            HStack(alignment: .bottom) {
                Text(title)
                    .textCase(.none)
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color(.label))
                 Spacer()
            }
        }
        
        return Section(header: header) {
            Text(description)
        }
    }
}

struct RestingEnergyEquationsInfo: View {
    
    @Environment(\.dismiss) var dismiss
    @State var hasAppeared = false
    
    var body: some View {
        NavigationStack {
            Group {
                if hasAppeared {
                    form
                } else {
                    Color.clear
                }
            }
            .navigationTitle("Equations")
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: appeared)
            .toolbar { toolbarContent }
        }
    }
    
    func appeared() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            hasAppeared = true
        }
    }
    
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Done") {
                dismiss()
            }
            .fontWeight(.semibold)
        }
    }
    
    var form: some View {
        Form {
            ForEach(RestingEnergyEquation.inOrderOfYear, id: \.self) {
                section(for: $0)
            }
        }
    }
    
    func section(for equation: RestingEnergyEquation) -> some View {
        var header: some View {
            HStack(alignment: .bottom) {
                Text(equation.name)
                    .textCase(.none)
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color(.label))
                 Spacer()
                 Text(equation.year)
                     .textCase(.none)
                     .font(.system(.title3, design: .rounded, weight: .medium))
                     .foregroundStyle(Color(.label))
            }
        }
        
        var variablesRow: some View {
            HStack(alignment: .firstTextBaseline) {
                Text("Uses")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(equation.variablesDescription)
                    .multilineTextAlignment(.trailing)
            }
        }
        
        return Section(header: header) {
            Text(equation.description)
            variablesRow
        }
    }
}

struct ActivityLevelInfo: View {
    
    @Environment(\.dismiss) var dismiss
    @State var hasAppeared = false
    
    var body: some View {
        NavigationStack {
            Group {
                if hasAppeared {
                    form
                } else {
                    Color.clear
                }
            }
            .navigationTitle("Activity Level")
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: appeared)
            .toolbar { toolbarContent }
        }
    }
    
    func appeared() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            hasAppeared = true
        }
    }
    
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Done") {
                dismiss()
            }
            .fontWeight(.semibold)
        }
    }
    
    var form: some View {
        Form {
            Section {
                Text("Choose an activity that matches your lifestyle.")
            }
            ForEach(ActivityLevel.allCases, id: \.self) {
                section(for: $0)
            }
        }
    }
    
    func section(for level: ActivityLevel) -> some View {
        var header: some View {
            HStack(alignment: .bottom) {
                Text(level.name)
                    .textCase(.none)
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color(.label))
                 Spacer()
            }
        }
        
        return Section(header: header) {
            Text(level.description)
        }
    }
}
