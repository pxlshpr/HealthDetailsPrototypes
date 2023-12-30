import SwiftUI

struct RestingEnergyInfo: View {
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            form
                .navigationTitle("Resting Energy")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
        }
    }
    
    var form: some View {
        Form {
            Section {
                Text("You can set your Resting Energy in three ways.")
            }
            InfoSection("Apple Health", "Use this if you want your Resting Energy to reflect what is recorded in the Apple Health app. This data will automatically vary daily depending on your level of activity.")
            InfoSection("Equation", "Use one of the many equations to calculate your Resting Energy. This value will mostly remain unchanged, unless the Health Details used changes.")
            InfoSection("Custom", "Choosing this will allow you to enter the Resting Energy manually.")
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
    RestingEnergyInfo()
}
