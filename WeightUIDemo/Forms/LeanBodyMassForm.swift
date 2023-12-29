import SwiftUI
import SwiftSugar

struct LeanBodyMassForm: View {
    
    @Environment(\.dismiss) var dismiss

    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24

    @State var hasAppeared = false
    @State var dailyValueType: DailyValueType = .average
    @State var value: Double = 73.6

    @State var isSynced: Bool = true
    @State var showingSyncOffConfirmation: Bool = false

    @State var showingForm = false
    
    @State var source: LeanBodyMassSource = .userEntered
    
    var body: some View {
        NavigationView {
            Group {
                if hasAppeared {
                    Form {
//                        explanation
                        list
                        dailyValuePicker
                        syncToggle
                    }
                } else {
                    Color.clear
                }
            }
            .navigationTitle("Lean Body Mass")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                hasAppeared = true
            }
        }
        .confirmationDialog("Turn Off Sync", isPresented: $showingSyncOffConfirmation, titleVisibility: .visible) {
            Button("Turn Off", role: .destructive) {
                
            }
        } message: {
            Text("Lean body mass data will no longer be read from or written to Apple Health.")
        }
        .sheet(isPresented: $showingForm) { form }
    }
    
    var form: some View {
        LeanBodyMassMeasurementForm()
    }
    
    var dailyValuePicker: some View {
        var picker: some View {
            Picker("", selection: $dailyValueType) {
                ForEach(DailyValueType.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
        }
        
        var description: String {
            let name = switch dailyValueType {
            case .average:  "average"
            case .last:     "last value"
            case .first:    "first value"
            }
            
            return "When multiple values are present, the \(name) is used for the day."

        }
        return Section("Daily Value") {
            picker
            Text(description)
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

        return Section(footer: Text("Automatically reads lean body mass data from Apple Health. Data you enter here will also be exported back to Apple Health.")) {
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
                Text("Your lean body mass is the weight of your body minus your body fat (adipose tissue). It may be used when:")
                dotPoint("Creating goals. For example, you could create a protein goal relative to your lean body mass instead of your weight.")
                dotPoint("Calculating your estimated resting energy.")
            }
        }
    }
    
    struct ListData: Hashable {
        let source: LeanBodyMassSource
        let dateString: String
        let valueString: String
        
        init(_ source: LeanBodyMassSource, _ dateString: String, _ valueString: String) {
            self.source = source
            self.dateString = dateString
            self.valueString = valueString
        }
    }
    
    let listData: [ListData] = [
        .init(.userEntered, "9:42 am", "73.7 kg"),
        .init(.healthKit, "12:07 pm", "74.6 kg"),
        .init(.fatPercentage, "1:23 pm", "72.3 kg"),
        .init(.equation, "3:01 pm", "70.9 kg"),
        .init(.userEntered, "5:35 pm", "72.5 kg"),
    ]
    
    func cell(for listData: ListData) -> some View {
        HStack {
            switch listData.source {
            case .healthKit:
                Image("AppleHealthIcon")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(.systemGray3), lineWidth: 0.5)
                    )
            default:
                Image(systemName: listData.source.image)
                    .scaleEffect(listData.source.scale)
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
        Section {
            ForEach(listData, id: \.self) {
                cell(for: $0)
                    .deleteDisabled($0.source == .healthKit)
            }
            .onDelete(perform: delete)
            Button {
                showingForm = true
            } label: {
                Text("Add Measurement")
            }
        }
    }
    
    func delete(at offsets: IndexSet) {

    }
}

#Preview("Lean Body Mass") {
    LeanBodyMassForm()
}
