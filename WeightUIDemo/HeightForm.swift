import SwiftUI
import SwiftSugar

struct HeightForm: View {
    
    @Environment(\.dismiss) var dismiss

    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24

    @State var value: Double = 177.4

    @State var isSynced: Bool = true
    @State var showingSyncOffConfirmation: Bool = false

    var body: some View {
        Form {
            explanation
            list
            syncToggle
        }
        .navigationTitle("Height")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .confirmationDialog("Turn Off Sync", isPresented: $showingSyncOffConfirmation, titleVisibility: .visible) {
            Button("Turn Off", role: .destructive) {
                
            }
        } message: {
            Text("Height data will no longer be read from or written to Apple Health.")
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

        return Section(footer: Text("Automatically reads height data from Apple Health. Data you enter here will also be exported back to Apple Health.")) {
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

    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Your height may be used when:")
                dotPoint("Calculating your estimated resting energy.")
                dotPoint("Calculating your lean body mass.")
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
            Section(footer: Text("The latest entry is always used.")) {
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
    }
    
    func delete(at offsets: IndexSet) {

    }
}

#Preview {
    HeightForm()
}
