import SwiftUI
import SwiftSugar

struct WeightChangePointForm: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State var hasAppeared = false
    @State var dailyWeightType: Int = 0
    @State var value: Double = 93.6
    
    @State var useMovingAverage = true
    @State var days: Int = 7
    @State var showingWeightSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if hasAppeared {
                    Form {
                        explanation
                        movingAverageToggle
                        lists
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
        .sheet(isPresented: $showingWeightSettings) {
            WeightSettings(
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
        
        return ForEach(range, id: \.self) { i in
            Section(header: header(i)) {
                if [0, 5, 6].contains(i) {
                    ForEach(listData, id: \.self) {
                        cell(for: $0)
                            .deleteDisabled($0.isHealth)
                    }
                    .onDelete(perform: delete)
                }
                Button {
                    
                } label: {
                    Text("Add Weight")
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
