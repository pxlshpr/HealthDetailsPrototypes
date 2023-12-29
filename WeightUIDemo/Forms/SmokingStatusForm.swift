import SwiftUI
import SwiftSugar

struct SmokingStatusForm: View {
    
    @State var hasAppeared = false
    @State var smokingStatus: SmokingStatus = .notSet
    
    var body: some View {
        NavigationView {
            Group {
                if hasAppeared {
                    Form {
                        explanation
                        picker
                    }
                } else {
                    Color.clear
                }
            }
            .navigationTitle("Smoking Status")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                hasAppeared = true
            }
        }
    }
    
    var picker: some View {
        PickerSection([SmokingStatus.nonSmoker, SmokingStatus.smoker], $smokingStatus)
    }

    var toolbarContent: some ToolbarContent {
        var smokingStatusLabel: String {
            smokingStatus.name
        }
        
        return Group {
            ToolbarItem(placement: .bottomBar) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Spacer()
                    Text(smokingStatusLabel)
                        .font(NotSetFont)
                        .foregroundStyle(smokingStatus == .noneOption ? .secondary : .primary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
//                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }

    var explanation: some View {
        Section {
            Text("Your smoking status may be used when picking daily values for micronutrients.\n\nFor example, if you are a smoker then the recommended daily allowance of Vitamin C will be slightly higher.")
        }
    }

}

#Preview {
    SmokingStatusForm()
}
