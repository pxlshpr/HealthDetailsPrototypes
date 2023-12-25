import SwiftUI
import SwiftSugar

struct PregnancyStatusForm: View {
    
    @Environment(\.dismiss) var dismiss

    @State var hasAppeared = false
    @State var pregnancyStatus: PregnancyStatus = .notSet
    
    var body: some View {
        NavigationStack {
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
            .navigationTitle("Pregnancy Status")
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
        PickerSection([PregnancyStatus.notPregnantOrLactating, PregnancyStatus.pregnant, PregnancyStatus.lactating], $pregnancyStatus)
    }

    var toolbarContent: some ToolbarContent {
        var valueLabel: String {
            pregnancyStatus.name
        }
        
        return Group {
            ToolbarItem(placement: .bottomBar) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Spacer()
                    Text(valueLabel)
                        .font(NotSetFont)
                        .foregroundStyle(pregnancyStatus == .noneOption ? .secondary : .primary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }

    var explanation: some View {
        Section {
            Text("Your pregnancy status may be used when picking daily values for micronutrients.\n\nFor example, the recommended daily allowance for Iodine almost doubles when a mother is breastfeeding.")
        }
    }

}

#Preview {
    PregnancyStatusForm()
}
