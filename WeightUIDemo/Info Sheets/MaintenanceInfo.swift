import SwiftUI

struct MaintenanceInfo: View {
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            form
                .navigationTitle("Calculation")
                .toolbar { toolbarContent }
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
                Text("Maintenance Energy")
                    .font(.headline)
            }
        }
    }
    
    var form: some View {
        Form {
            Section {
                Text("Your Maintenance Energy can be calculated in two ways.")
            }
            InfoSection("Adaptive", "The Adaptive Calculation compares your weight change to the energy you consumed over a specified period. It then uses the energy balance equation to determine what your dietary energy should have been to result in no weight change, ie. your Maintenance Energy.\n\nIt is considerably more accurate than the Estimated Calculation as it is personalised to your body weight's particular response to the energy you consume. It would also correct itself over time as long as you are weighing yourself and logging the food you eat reasonably accurately.")
            InfoSection("Estimated", "The Estimated Calculation determines the daily Resting Energy and Active Energy components and adds them together. Each of these components have various ways of estimating them.\n\nHowever, it is not personalised to your body's unique metabolic response to the food you eat, and should be considered as more of an approximation.")
        }
    }
}
