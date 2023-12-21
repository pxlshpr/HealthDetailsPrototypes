import SwiftUI
import SwiftSugar

struct WeightChangePointForm: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State var hasAppeared = false
    @State var dailyValueType: DailyValueType = .average
    @State var value: Double = 93.6
    
    @State var useMovingAverage = true
    @State var days: Int = 7
    
    @State var isSynced: Bool = true
    @State var showingSyncOffConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                if hasAppeared {
                    Form {
                        explanation
                        movingAverageToggle
                        dailyValuePicker
                        lists
                        syncToggle
                    }
                } else {
                    Color.clear
                }
            }
            .navigationTitle("Current Weight")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                hasAppeared = true
            }
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

        return Section(footer: Text("Automatically reads weight data from Apple Health. Entered weights will be exported to it as well.")) {
            HStack {
                Text("Sync with Health App")
                    .layoutPriority(1)
                Spacer()
                Toggle("", isOn: binding)
            }
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
                Text("This is used to calculate the change in your weight.")
            }
        }
    }
    
    var movingAverageToggle: some View {
        let binding = Binding<Bool>(
            get: { useMovingAverage },
            set: { newValue in
                withAnimation {
                    useMovingAverage = newValue
                }
            }
        )
        let daysBinding = Binding<Int>(
            get: { days },
            set: { newValue in
                withAnimation {
                    days = newValue
                }
            }
        )
        return Section(footer: Text("Use a moving average of multiple days to smooth out short-term fluctuations.")) {
            HStack {
                Text("Use a Moving Average")
                    .layoutPriority(1)
                Spacer()
                Toggle("", isOn: binding)
            }
            if useMovingAverage {
                HStack(spacing: 3) {
                    Stepper(
                        "",
                        value: daysBinding,
                        in: 2...7
                    )
                    .fixedSize()
                    Spacer()
                    Text("\(days)")
                        .contentTransition(.numericText(value: Double(days)))
                    Text("days")
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
    
    let emptyListData: [ListData] = []
    
    var lists: some View {
        @ViewBuilder
        func header(_ i: Int) -> some View {
            if useMovingAverage {
                Text(Date.now.moveDayBy(-i).dateString)
            } else {
                EmptyView()
            }
        }
        var range: Range<Int> {
            useMovingAverage ? 0..<days : 0..<1
        }
        
        @ViewBuilder
        func footer(_ i: Int) -> some View {
            if [0, 5, 6].contains(i) {
                Text(dailyValueType.description)
            }
        }
        
        return ForEach(range, id: \.self) { i in
            Section(header: header(i), footer: footer(i)) {
                if [0, 5, 6].contains(i) {
                    ForEach(listData, id: \.self) {
                        cell(for: $0)
                            .deleteDisabled($0.isHealth)
                    }
                    .onDelete(perform: delete)
                }
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
    WeightChangePointForm()
}
