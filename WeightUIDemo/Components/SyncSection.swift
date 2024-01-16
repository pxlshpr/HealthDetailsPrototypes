import SwiftUI

struct SyncSection: View {
    
    let healthDetail: HealthDetail
    @Binding var isSynced: Bool
    let handleChanges: () -> ()
    
    @State var showingSyncOffConfirmation: Bool = false

    var body: some View {
        Section(footer: Text("Continuously import your \(healthDetail.name) data from Apple Health. Data you enter here will also be exported back to Apple Health.")) {
            HStack {
                AppleHealthIcon()
                Text("Sync with Apple Health")
                    .layoutPriority(1)
                Spacer()
                Toggle("", isOn: binding)
            }
        }
        .confirmationDialog("Turn Off Sync", isPresented: $showingSyncOffConfirmation, titleVisibility: .visible) {
            Button("Turn Off", role: .destructive) {
                isSynced = false
                handleChanges()
            }
        } message: {
            Text("\(healthDetail.name) data will no longer be read from or written to Apple Health.")
        }
    }
    
    var binding: Binding<Bool> {
        Binding<Bool>(
            get: { isSynced },
            set: { newValue in
                if !newValue {
                    showingSyncOffConfirmation = true
                } else {
                    isSynced = newValue
                    handleChanges()
                }
            }
        )
    }
}
