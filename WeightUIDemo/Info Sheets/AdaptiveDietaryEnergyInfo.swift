import SwiftUI

struct AdaptiveDietaryEnergyInfo: View {
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            form
                .navigationTitle("Setting Dietary Energy")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
        }
    }
    
    var form: some View {
        Form {
            InfoSection("Use Log", "This will use the energy total from your food log.\n\nChoose this if you reliably logged all the food you consumed on this date.")
            InfoSection("Use Apple Health", "This will fetch the data recorded in the Apple Health for this date.\n\nChoose this if you have the correct data in there, either entered manually or exported from another app.")
            InfoSection("Set as Fasted", "This will mark this day as fasted by assigning it a Dietary Energy of zero.\n\nMake sure you choose this for the days where you consumed no calories, as they would be assigned the average of the other days otherwise.")
            InfoSection("Exclude and Use Average", "This will exclude this day's Dietary Energy and instead assign it the average of the other days.\n\nChoose this if you don't believe you have a complete and accurate log of the food you ate for this date.")
            InfoSection("Enter Manually", "Choosing this will allow you to enter the Dietary Energy manually.")
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
}

#Preview {
    AdaptiveDietaryEnergyInfo()
}
