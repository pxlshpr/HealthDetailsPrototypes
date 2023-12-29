import SwiftUI
import SwiftSugar

struct SexForm: View {
    
    @State var value: Double = 93.6
    @State var showingWeightSettings = false
    @State var sex: Sex = .other
    
    var body: some View {
        Form {
            explanation
            picker
        }
        .navigationTitle("Biological Sex")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
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
//                    dismiss()
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
