import SwiftUI

struct AdaptiveMaintenanceInfo: View {
    
    @Environment(\.dismiss) var dismiss

    @Binding var interval: HealthInterval
    
    var body: some View {
        NavigationView {
            form
                .navigationTitle("Adaptive")
                .toolbar { toolbarContent }
        }
    }
    
    var form: some View {
        Form {
            section
        }
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    dismiss()
                } label: {
                    CloseButtonLabel()
                }
//                Button("Done") {
//                    dismiss()
//                }
//                .fontWeight(.semibold)
            }
            ToolbarItem(placement: .principal) {
                Text("Maintenance Calculation")
                    .font(.headline)
            }
        }
    }
    
    var weeks: Int {
        interval.weeks ?? 1
    }
    
    var section: some View {
        Group {
            Section {
                Text("Your Adaptive Maintenance Energy is being calculated by comparing your weight change to the energy you consumed over the past \(weeks) week\(weeks > 1 ? "s" : "").")
            }
            
            Section {
                VStack(alignment: .leading) {
                    Text("This utilises the energy balance equation which states that:")
                    Text("Energy In – Energy Out = Energy Balance")
                        .infoEquationStyle()
                }
            }
            Section {
                VStack(alignment: .leading) {
                    Text("This can be thought of as:")
                    Text("Dietary Energy – Expenditure = Weight Change")
                        .infoEquationStyle()
                }
            }
            Section {
                VStack(alignment: .leading) {
                    Text("Rearranging this, we get:")
                    Text("Expenditure = Dietary Energy - Weight Change")
                        .infoEquationStyle()
                }
            }
            Section {
                Text("This calculated **Expenditure** is the energy that you would have had to consume to result in a net zero change in weight, or in other words your Maintenance Energy.")
            }
        }
        
    }
}
