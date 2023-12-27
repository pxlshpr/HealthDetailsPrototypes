import SwiftUI

struct AdaptiveDietaryEnergyInfo: View {
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            form
                .navigationTitle("Setting Dietary Energy")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    var form: some View {
        Form {
            InfoSection("Log", "This will use the energy total from your food log.\n\nChoose this if you reliably logged all the food you consumed on this date.")
            InfoSection("Apple Health", "This will fetch the data recorded in the Apple Health for this date.\n\nChoose this if you have the correct data in there, either entered manually or exported from another app.")
            InfoSection("Fasted", "This will mark this day as fasted by assigning it a dietary energy of zero.\n\nMake sure you choose this for the days where you consumed no calories, as they would be assigned the average of the other days otherwise.")
            InfoSection("Use Average", "This will exclude this day's dietary energy and instead assign it the average of the other days.\n\nChoose this if you don't believe you have a complete and accurate log of the food you ate for this date.")
            InfoSection("Custom", "Choosing this will allow you to enter the dietary energy manually.")
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
}

#Preview {
    AdaptiveDietaryEnergyInfo()
}
