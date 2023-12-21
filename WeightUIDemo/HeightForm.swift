import SwiftUI
import SwiftSugar

struct HeightForm: View {
    
    @Environment(\.dismiss) var dismiss

    @State var hasAppeared = false
    @State var dailyWeightType: Int = 0
    @State var value: Double = 177.4
    @State var showingWeightSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if hasAppeared {
                    Form {
                        explanation
//                        weightSettings
                        list
//                        valueSection
                    }
                } else {
                    Color.clear
                }
            }
            .navigationTitle("Height")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                hasAppeared = true
            }
        }
        .sheet(isPresented: $showingWeightSettings) {
            HeightSettings(
                dailyWeightType: $dailyWeightType,
                value: $value
            )
        }
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .bottomBar) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Button {
                        showingWeightSettings = true
                    } label: {
                        Image(systemName: "switch.2")
                    }
                    Spacer()
                    Text("\(value.clean)")
                        .contentTransition(.numericText(value: value))
                        .font(LargeNumberFont)
                    Text("cm")
                        .font(LargeUnitFont)
                        .foregroundStyle(.secondary)
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
                Text("Your height may be used to:")
                Label {
                    Text("Calculate your estimated resting energy.")
                } icon: {
                    Circle()
                        .foregroundStyle(Color(.label))
                        .frame(width: 5, height: 5)
                }
                Label {
                    Text("Calculate your lean body mass.")
                } icon: {
                    Circle()
                        .foregroundStyle(Color(.label))
                        .frame(width: 5, height: 5)
                }
            }
        }
    }
    
    struct ListData: Hashable {
        let isHealth: Bool
        let dateString: String
        let valueString: String
        
        init(_ isHealth: Bool, _ dateString: String, _ valueString: String) {
            self.isHealth = isHealth
            self.dateString = dateString
            self.valueString = valueString
        }
    }
    
    let listData: [ListData] = [
        .init(false, "9:42 am", "117.3 cm"),
        .init(true, "12:07 pm", "117.6 cm"),
        .init(false, "5:35 pm", "117.4 cm"),
    ]

    func cell(for listData: ListData) -> some View {
        HStack {
            if listData.isHealth {
                Image("AppleHealthIcon")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(.systemGray3), lineWidth: 0.5)
                    )
            } else {
                Image(systemName: "pencil")
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundStyle(Color(.systemGray4))
                    )
            }
            Text(listData.dateString)
            
            Spacer()
            Text(listData.valueString)
        }
    }
    
    var list: some View {
        Group {
            Section(footer: Text("The latest measurement is always used.")) {
                ForEach(listData, id: \.self) {
                    cell(for: $0)
                        .deleteDisabled($0.isHealth)
                }
                .onDelete(perform: delete)
            }
            Section {
                Button {
                    
                } label: {
                    Text("Add Measurement")
                }
            }
        }
    }
    
    func delete(at offsets: IndexSet) {

    }
    
    var valueSection: some View {
        Section {
            HStack {
                Spacer()
                Text("\(value.clean)")
                    .contentTransition(.numericText(value: value))
                    .font(LargeNumberFont)
            }
        }
    }
}

#Preview {
    HeightForm()
}
