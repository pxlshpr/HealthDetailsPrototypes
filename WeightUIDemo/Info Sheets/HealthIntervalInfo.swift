import SwiftUI

struct HealthIntervalInfo: View {
    
    @Environment(\.dismiss) var dismiss
    
    let isRestingEnergy: Bool

    var body: some View {
        NavigationView {
            form
                .navigationTitle("Health App Data")
                .navigationBarTitleDisplayMode(.large)
                .toolbar { toolbarContent }
        }
    }
    
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                dismiss()
            } label: {
                CloseButtonLabel()
            }
//            Button("Done") {
//                dismiss()
//            }
//            .fontWeight(.semibold)
        }
    }
    
    var form: some View {
        Form {
            Section {
                Text("Your \(isRestingEnergy ? "Resting" : "Active") Energy data can be read from Apple Health in three ways.")
            }
            InfoSection("Daily Average", "Uses the daily average of of the specified number of days leading up to the date.")
            InfoSection("Today's Data", "Uses the data for the current day. Use this if you want your goals to reflect how active you are throughout the day. Keep in mind that this value will keep increasing until the day is over.")
            InfoSection("Yesterday's Data", "Uses the data for the previous day. Use this if you want your goals to reflect how active you were the day before.")
        }
    }
}
