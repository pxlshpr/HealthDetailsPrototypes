import SwiftUI

struct ActiveEnergyInfo: View {
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            form
                .navigationTitle("Active Energy")
                .navigationBarTitleDisplayMode(.large)
                .toolbar { toolbarContent }
        }
    }
    
    var form: some View {
        Form {
            Section {
                Text("You can set your Active Energy in three ways.")
            }
            InfoSection("Apple Health", "Use this if you want your Active Energy to reflect what is recorded in the Apple Health app. This data will automatically vary daily depending on your level of activity.")
            InfoSection("Activity Level", "Use a multiplier on your Resting energy based on how active you are.")
            InfoSection("Custom", "Choosing this will allow you to enter the Active Energy manually.")
        }
    }
    
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
//            Button("Done") {
//                dismiss()
//            }
//            .fontWeight(.semibold)
            Button {
                dismiss()
            } label: {
                CloseButtonLabel()
            }
        }
    }
}

#Preview {
    ActiveEnergyInfo()
}
