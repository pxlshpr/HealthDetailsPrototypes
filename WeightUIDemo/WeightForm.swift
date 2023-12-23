import SwiftUI
import SwiftSugar

struct WeightForm: View {
    
    @Environment(\.dismiss) var dismiss

    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24

    @State var dailyValueType: DailyValueType = .average
    @State var value: Double = 93.6

    @State var isSynced: Bool = true
    @State var showingSyncOffConfirmation: Bool = false

    var body: some View {
        Form {
            explanation
            dailyValuePicker
            list
            syncToggle
        }
        .navigationTitle("Weight")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .confirmationDialog("Turn Off Sync", isPresented: $showingSyncOffConfirmation, titleVisibility: .visible) {
            Button("Turn Off", role: .destructive) {
                
            }
        } message: {
            Text("Weight data will no longer be read from or written to Apple Health.")
        }

    }
    
    var dailyValuePicker: some View {
        Section("Use") {
            Picker("", selection: $dailyValueType) {
                ForEach(DailyValueType.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    var syncToggle: some View {
        let binding = Binding<Bool>(
            get: { isSynced },
            set: {
                if !$0 {
                    showingSyncOffConfirmation = true
                }
            }
        )

        return Section(footer: Text("Automatically reads weight data from Apple Health. Data you enter here will also be exported back to Apple Health.")) {
            HStack {
                Image("AppleHealthIcon")
                    .resizable()
                    .frame(width: imageScale * scale, height: imageScale * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(.systemGray3), lineWidth: 0.5)
                    )
                Text("Sync with Apple Health")
                    .layoutPriority(1)
                Spacer()
                Toggle("", isOn: binding)
            }
        }
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .bottomBar) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Spacer()
                    Text("\(value.clean)")
                        .contentTransition(.numericText(value: value))
                        .font(LargeNumberFont)
                    Text("kg")
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

    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Your weight may be used when:")
                dotPoint("Creating goals. For example, you could create a protein goal relative to your weight.")
                dotPoint("Calculating your adaptive maintenance energy, estimated resting energy, or lean body mass.")
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
        .init(false, "9:42 am", "93.7 kg"),
        .init(true, "12:07 pm", "94.6 kg"),
        .init(false, "5:35 pm", "92.5 kg"),
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
        var footer: some View {
            Text(dailyValueType.description)
        }

        return Section(footer: footer) {
            ForEach(listData, id: \.self) {
                cell(for: $0)
                    .deleteDisabled($0.isHealth)
            }
            .onDelete(perform: delete)
            Button {
                
            } label: {
                Text("Add Measurement")
            }
        }
    }
    
    func delete(at offsets: IndexSet) {

    }
}

#Preview {
    WeightForm()
}
