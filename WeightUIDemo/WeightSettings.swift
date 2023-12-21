import SwiftUI

struct WeightSettings: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var dailyWeightType: Int
    @Binding var value: Double

    @State var isSynced: Bool = true
    @State var showingSyncOffConfirmation: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                explanation
                syncToggle
                dailyWeightPicker
            }
            .navigationTitle("Weight Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .presentationDetents([.medium])
        .confirmationDialog("Turn Off Sync", isPresented: $showingSyncOffConfirmation, titleVisibility: .visible) {
            Button("Turn Off", role: .destructive) {
                
            }
        } message: {
            Text("Weight data will no longer be read from or written to Apple Health.")
        }
    }
    
    var explanation: some View {
        Section {
            VStack {
                Text("These settings apply to all your weight data.")
            }
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
    
    var syncToggle: some View {
        Section(footer: Text("Retrieves weight data from Apple Health automatically. Any weights entered here will be exported to Apple Health as well.")) {
            HStack {
                Text("Sync with Health App")
                    .layoutPriority(1)
                Spacer()
                Toggle("", isOn: syncBinding)
            }
        }
    }
    
    var syncBinding: Binding<Bool> {
        Binding<Bool>(
            get: { isSynced },
            set: {
                if !$0 {
                    showingSyncOffConfirmation = true
                }
            }
        )
    }
    
    var dailyWeightPicker: some View {
        DailyWeightPicker(
            dailyWeightType: $dailyWeightType,
            value: $value,
            isDisabled: .constant(false)
        )
    }
}

struct WeightSettingsPreview: View {
    @State var dailyWeightType: Int = 0
    @State var value: Double = 0
    
    var body: some View {
        WeightSettings(
            dailyWeightType: $dailyWeightType,
            value: $value
        )
    }
}
#Preview {
    WeightSettingsPreview()
}
