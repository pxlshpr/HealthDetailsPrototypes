import SwiftUI

struct AppleHealthCorrectionInfo: View {
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            form
                .navigationTitle("Correction")
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
                Text("Depending on the source of your Energy Expenditure data in Apple Health, you may want to apply a correction to account for possible errors.\n\nThere have been numerous studies, such as [this one](https://www.mdpi.com/2075-4426/7/2/3) from a group at Stanford, that report that the energy expenditure data recorded by most wristband activity monitors are error-prone. Read more about it [here](https://med.stanford.edu/news/all-news/2017/05/fitness-trackers-accurately-measure-heart-rate-but-not-calories-burned.html?tab=proxy).\n\nThere are a few ways you can do this.")
            }
            InfoSection("Add", "Choosing this will add whatever value you enter to the data read from Apple Health.\n\nUse this if you believe that the data is an underestimate.")
            InfoSection("Subtract", "Choosing this will subtract whatever value you enter from the data read from Apple Health.\n\nUse this if you believe that the data is an overestimate.")
            InfoSection("Multiply", "Choosing this will apply a multiplier to the data read from Apple Health.\n\nUse this if you believe that the data is an underestimate.")
            InfoSection("Divide", "Choosing this will divide the data read from Apple Health.\n\nFor instance, you can set a value of 2 to always use only half of the recorded value.\n\nUse this if you believe that the data is an overestimate.")
        }
    }
}
