//import SwiftUI
//
//struct LeanBodyMassSettings: View {
//    
//    @Environment(\.dismiss) var dismiss
//    @Binding var dailyWeightType: Int
//    @Binding var value: Double
//
//    @State var isSynced: Bool = true
//    @State var showingSyncOffConfirmation: Bool = false
//    
//    var body: some View {
//        NavigationView {
//            Form {
//                explanation
//                syncToggle
//                dailyWeightPicker
//            }
//            .navigationTitle("Lean Body Mass Settings")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar { toolbarContent }
//        }
//        .presentationDetents([.medium])
//        .confirmationDialog("Turn Off Sync", isPresented: $showingSyncOffConfirmation, titleVisibility: .visible) {
//            Button("Turn Off", role: .destructive) {
//                
//            }
//        } message: {
//            Text("Lean Body Mass data will no longer be read from or written to Apple Health.")
//        }
//    }
//    
//    var explanation: some View {
//        Section {
//            VStack {
//                Text("These settings apply to all your lean body mass data.")
//            }
//        }
//    }
//    
//    var toolbarContent: some ToolbarContent {
//        ToolbarItem(placement: .topBarTrailing) {
//            Button("Done") {
//                dismiss()
//            }
//            .fontWeight(.semibold)
//        }
//    }
//    
//    var syncToggle: some View {
//        Section(footer: Text("Retrieves lean body mass data from Apple Health automatically. Any data entered here will be exported to Apple Health as well.")) {
//            HStack {
//                Text("Sync with Health App")
//                    .layoutPriority(1)
//                Spacer()
//                Toggle("", isOn: syncBinding)
//            }
//        }
//    }
//    
//    var syncBinding: Binding<Bool> {
//        Binding<Bool>(
//            get: { isSynced },
//            set: {
//                if !$0 {
//                    showingSyncOffConfirmation = true
//                }
//            }
//        )
//    }
//    
//    var dailyWeightPicker: some View {
//        DailyLeanBodyMassPicker(
//            dailyWeightType: $dailyWeightType,
//            value: $value,
//            isDisabled: .constant(false)
//        )
//    }
//}
//
//struct LeanBodyMassSettingsPreview: View {
//    @State var dailyWeightType: Int = 0
//    @State var value: Double = 0
//    
//    var body: some View {
//        LeanBodyMassSettings(
//            dailyWeightType: $dailyWeightType,
//            value: $value
//        )
//    }
//}
//#Preview {
//    LeanBodyMassSettingsPreview()
//}
