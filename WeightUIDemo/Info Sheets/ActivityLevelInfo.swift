import SwiftUI

struct ActivityLevelInfo: View {
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            form
                .navigationTitle("Activity Level")
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
                Text("Choose an activity that matches your lifestyle.")
            }
            ForEach(ActivityLevel.allCases, id: \.self) {
                section(for: $0)
            }
        }
    }
    
    func section(for level: ActivityLevel) -> some View {
        var header: some View {
            HStack(alignment: .bottom) {
                Text(level.name)
                    .textCase(.none)
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color(.label))
                 Spacer()
            }
        }
        
        return Section(header: header) {
            Text(level.description)
        }
    }
}
