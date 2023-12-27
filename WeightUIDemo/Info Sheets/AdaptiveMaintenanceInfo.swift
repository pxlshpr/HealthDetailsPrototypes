import SwiftUI

struct AdaptiveMaintenanceInfo: View {
    
    @Environment(\.dismiss) var dismiss

    @Binding var weeks: Int
    
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
                Button("Done") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
            ToolbarItem(placement: .principal) {
                Text("Maintenance Calculation")
                    .font(.headline)
            }
        }
    }
    
    var section: some View {
        Group {
            Section {
                Text("Your adaptive maintenance is being calculated by comparing your weight change to the energy you consumed over the past \(weeks) week\(weeks > 1 ? "s" : "").")
            }
            
            Section {
                VStack(alignment: .leading) {
                    Text("This utilises the energy balance equation which states that:")
                    Text("Energy In – Energy Out = Energy Balance")
                        .font(.footnote)
                        .padding(5)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .foregroundStyle(Color(.systemGray5))
                        )
                }
            }
            Section {
                VStack(alignment: .leading) {
                    Text("This can be thought of as:")
                    Text("Dietary Energy – Expenditure = Weight Change")
                        .font(.footnote)
                        .padding(5)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .foregroundStyle(Color(.systemGray5))
                        )
                }
            }
            Section {
                VStack(alignment: .leading) {
                    Text("Rearranging this, we get:")
                    Text("Expenditure = Dietary Energy - Weight Change")
                        .font(.footnote)
                        .padding(5)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .foregroundStyle(Color(.systemGray5))
                        )
                }
            }
            Section {
                Text("This calculated **Expenditure** is the energy that you would have had to consume to result in a net zero change in weight, or in other words your Maintenance Energy.")
            }
        }
        
    }
}

#Preview {
    AdaptiveMaintenanceInfo(weeks: .constant(1))
}
