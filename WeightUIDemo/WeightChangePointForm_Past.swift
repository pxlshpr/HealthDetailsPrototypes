import SwiftUI
import SwiftSugar

let LargeUnitFont: Font = .system(.title3, design: .rounded, weight: .semibold)
let NotSetFont = LargeNumberFont

struct WeightChangePointForm_Past: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State var hasAppeared = false
    @State var dailyWeightType: Int = 0
    @State var value: Double = 93.6
    
    @State var useMovingAverage = true
    @State var days: Int = 7

    @State var isEditing = false
    @State var showingWeightSettings = false
    
    var body: some View {
        NavigationStack {
            Group {
                if hasAppeared {
                    Form {
                        explanation
                        if !isEditing {
                            notice
                        }
//                        weightSettings
                        if !isEditing {
                            dailyWeightPicker
                        }
                        movingAverageToggle
                        lists
//                        valueSection
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
    
    var settingsHeader: some View {
        Section {
            Text("Settings")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .listRowBackground(EmptyView())
        }
    }

    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        withAnimation {
                            isEditing = false
                        }
                    } else {
                        withAnimation {
                            isEditing = true
                        }
                    }
                }
                .fontWeight(.semibold)
            }
            ToolbarItem(placement: .topBarLeading) {
                if isEditing {
                    Button("Cancel") {
                        withAnimation {
                            isEditing = false
                        }
                    }
                }
            }
            ToolbarItem(placement: .bottomBar) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    if isEditing {
                        Button {
                            showingWeightSettings = true
                        } label: {
                            Image(systemName: "switch.2")
                        }
                    }
                    Spacer()
                    Text("\(value.clean)")
                        .contentTransition(.numericText(value: value))
                        .font(LargeNumberFont)
                        .foregroundStyle(isDisabled ? .secondary : .primary)
                    Text("kg")
                        .font(LargeUnitFont)
//                        .foregroundStyle(.secondary)
                        .foregroundStyle(isDisabled ? .tertiary : .secondary)
                }
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
    
    var notice: some View {
        var primaryAction: NoticeAction {
            .init(title: isEditing ? "View Preserved Data" : "Edit to View Actual Data") {
                withAnimation {
                    isEditing.toggle()
                }
            }
        }
        
        var image: some View {
            var primaryColor: Color {
                isEditing ? .green : .yellow
            }
            
            var systemName: String {
                "calendar.badge.clock"
            }
            
            return Image(systemName: systemName)
                .font(.system(size: 30))
                .padding(5)
        }
        
        var message: String {
            isEditing
//            ? "You're viewing your current weight data, which may differ from what was set previously."
            ? "You are viewing current weight data, which may differ from what was saved previously."
//            ? "You are viewing your actual weight data for a past date which may have changed since you set it.\n\nUpdating will overwrite previously saved data and modify any dependent goals for that day."
//            : "You're currently viewing data that has been preserved despite possibly having changed since then, ensuring the goals set on that day remain unchanged."
//            : "You are viewing previously saved data that may have changed."
            : "This data has been preserved to ensure any goals set on this day remain unchanged."
//            : "You are viewing data of a past date that was set on that day and preserved to ensure your goals remain unchanged.\n\nYour actual weight data may have changed since then."
        }
        
        var title: String {
            isEditing
            ? "Current Data"
            : "Previous Data"
        }
        
        var section: some View {
            NoticeSection(
                style: .plain,
                title: title,
                message: message,
//                primaryAction: primaryAction,
                image: { image }
            )
        }
        
        return Group {
//            if !isEditing {
                section
//            }
        }
    }

    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("This is used to calculate the change in your weight.")
            }
        }
    }
    
    var controlColor: Color {
        isEditing ? Color(.label) : Color(.secondaryLabel)
    }
    
    var isDisabled: Bool {
        !isEditing
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
        
        var toggleRow: some View {
            var label: some View {
                Text("Use a Moving Average")
                    .foregroundStyle(controlColor)
                    .layoutPriority(1)
            }
            
            var toggle: some View {
                Toggle("", isOn: binding)
                    .disabled(isDisabled)
            }
            
            return HStack {
                label
                Spacer()
                toggle
            }
        }

        var footer: some View {
            Text("Use a moving average of preceding days to smooth out short-term fluctuations.")
        }
        
        var stepperRow: some View {
            var stepper: some View {
                Stepper(
                    "",
                    value: daysBinding,
                    in: 2...7
                )
                .fixedSize()
                .disabled(isDisabled)
            }
            
            var daysLabel: some View {
                Group {
                    Text("\(days)")
                        .contentTransition(.numericText(value: Double(days)))
                    Text("days")
                }
                .foregroundStyle(controlColor)
            }
            
            return HStack(spacing: 3) {
                stepper
                Spacer()
                daysLabel
            }
        }
        
        return Section(footer: footer) {
            toggleRow
            if useMovingAverage {
                stepperRow
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
        
        @ViewBuilder
        var image: some View {
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
        }
        
        return HStack {
            image
                .opacity(isEditing ? 1 : 0.6)
            Text(listData.dateString)
            Spacer()
            Text(listData.valueString)
        }
        .foregroundStyle(controlColor)
    }
    
    let emptyListData: [ListData] = []
    
    var dailyWeightPicker: some View {
        DailyWeightPicker(
            dailyWeightType: $dailyWeightType,
            value: $value,
            isDisabled: Binding<Bool>(
                get: { isDisabled },
                set: { _ in }
            )
        )
    }
    
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
        
        func bottomContent(_ i: Int) -> some View {
            
            var isEmpty: Bool {
                !indexesWithValues.contains(i)
            }
            
            var label: String {
                isEditing ? "Add Measurement" : "Not Set"
            }
            
            var color: Color {
                isEditing ? Color.accentColor : Color(.tertiaryLabel)
            }
            var button: some View {
                Button {
                    
                } label: {
                    Text(label)
                        .foregroundStyle(color)
                }
                .disabled(!isEditing)
            }
            
            return Group {
                if isEditing || isEmpty {
                    button
                }
            }
        }
        
        var indexesWithValues: [Int] {
            [0, 5, 6]
        }
        
        func isEmpty(_ i: Int) -> Bool {
            !indexesWithValues.contains(i)
        }
        
        @ViewBuilder
        func emptyContent(_ i: Int) -> some View {
            if isEmpty(i), !isEditing {
                Text("Not Set")
                    .foregroundStyle(.secondary)
            }
        }
        
        return ForEach(range, id: \.self) { i in
            Section(header: header(i)) {
                if indexesWithValues.contains(i) {
                    ForEach(listData, id: \.self) {
                        cell(for: $0)
                            .deleteDisabled($0.isHealth)
                    }
                    .onDelete(perform: delete)
                }
                bottomContent(i)
            }
        }
    }
    
    func delete(at offsets: IndexSet) {

    }
    
    var valueSection: some View {
        Section {
            HStack(alignment: .firstTextBaseline) {
                Spacer()
                Text("\(value.clean)")
                    .contentTransition(.numericText(value: value))
                    .font(LargeNumberFont)
            }
        }
    }
}

#Preview {
    WeightChangePointForm_Past()
}
