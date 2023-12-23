import SwiftUI
import SwiftSugar

struct SexForm: View {
    
    @Environment(\.dismiss) var dismiss

    @State var hasAppeared = false
    @State var value: Double = 93.6
    @State var showingWeightSettings = false
    @State var sex: Sex = .other
    
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
            .navigationTitle("Biological Sex")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                hasAppeared = true
            }
        }
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .bottomBar) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Spacer()
                    Text(sex != .other ? sex.name : "Not Set")
                        .font(NotSetFont)
                        .foregroundStyle(sex != .other ? .primary : .secondary)
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

    var weightSettings: some View {
        Button {
            showingWeightSettings = true
        } label: {
            Text("Weight Settings")
        }
    }
    
    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Your biological sex may be used when:")
                dotPoint("Calculating your estimated resting energy or lean body mass.")
                dotPoint("Picking daily values for micronutrients.")
            }
        }
    }

    var picker: some View {
        PickerSection([Sex.female, Sex.male], $sex)
    }
}

#Preview {
    SexForm()
}
