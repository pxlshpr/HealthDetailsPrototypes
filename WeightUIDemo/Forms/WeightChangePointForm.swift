import SwiftUI
import SwiftSugar

struct WeightChangePointForm: View {
    
    @State var dailyValueType: DailyValueType = .average
    @State var value: Double? = 93.6
    
    @State var useMovingAverage = true
    @State var days: Int = 7
    
    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24

    let dateString: String
    let isCurrent: Bool
    
    let pastDate: Date?
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool

    init(
        pastDate: Date? = nil,
        isPresented: Binding<Bool> = .constant(true),
        dateString: String = MockPastDate.shortDateString,
        isCurrent: Bool = false
    ) {
        self.pastDate = pastDate
        self.dateString = dateString
        self.isCurrent = isCurrent
        _isPresented = isPresented
        _isEditing = State(initialValue: pastDate == nil)
    }

    var body: some View {
        Form {
            notice
            movingAverageToggle
            weights
            explanation
        }
        .navigationTitle(dateString)
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isPast && isEditing)
        .interactiveDismissDisabled(isPast && isEditing && isDirty)
    }
    
    var bottomValue: some View {
        BottomValue(
            value: $value,
            valueString: Binding<String?>(
                get: { value?.clean },
                set: { _ in }
            ),
            isDisabled: Binding<Bool>(
                get: { !isEditing },
                set: { _ in }
            ),
            unitString: "kg"
        )
    }
    
    var weights: some View {
        func link(date: Date, weight: Double?) -> some View {
            NavigationLink {
                
            } label: {
                HStack {
                    Text(date.shortDateString)
                    Spacer()
                    if let weight {
                        Text("\(weight.clean) kg")
                    } else {
                        Text("Not Set")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isPast && isEditing)
        }
        
        func weight(for date: Date) -> Double? {
            switch date.shortDateString {
            case "24 Dec": 93.6
            case "23 Dec": nil
            case "22 Dec": 94.7
            case "21 Dec": 94.2
            case "20 Dec": nil
            case "19 Dec": 95.1
            case "18 Dec": 95.4
            default: nil
            }
        }
        
        func link(at index: Int) -> some View {
            let date = MockPastDate.moveDayBy(-index)
            return link(
                date: date,
                weight: weight(for: date)
            )
        }
        
        return Section {
            link(at: 0)
//            link(date: MockPastDate, weight: 93.6)
            if useMovingAverage {
                ForEach(1..<days, id: \.self) { i in
                    link(at: i)
                }
            }
        }
    }
    
    
    var isPast: Bool {
        pastDate != nil
    }
    
    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: $isEditing)
        }
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            topToolbarContent(
                isEditing: $isEditing,
                isDirty: $isDirty,
                isPast: isPast,
                dismissAction: { isPresented = false },
                undoAction: undo,
                saveAction: save
            )
            ToolbarItem(placement: .principal) {
                Text("\(isCurrent ? "Current" : "Previous") Weight")
                    .font(.headline)
            }
        }
    }
    
    func save() {
        
    }
    
    func undo() {
        isDirty = false
        useMovingAverage = true
        days = 7
    }
    
    func setIsDirty() {
        isDirty = useMovingAverage != true
        || days != 7
    }
    
    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("This is used to determine your weight change, which is then used to calculate your Adaptive Maintenance Energy.\n\nYou can choose to use a moving average of multiple prior days to smooth out any short-term fluctuations.")
            }
        }
    }
    
    var movingAverageToggle: some View {
        let binding = Binding<Bool>(
            get: { useMovingAverage },
            set: { newValue in
                withAnimation {
                    useMovingAverage = newValue
                    setIsDirty()
                }
            }
        )
        let daysBinding = Binding<Int>(
            get: { days },
            set: { newValue in
                withAnimation {
                    days = newValue
                    setIsDirty()
                }
            }
        )
        
        return Section {
            HStack {
                Text("Use a Moving Average")
                    .layoutPriority(1)
                Spacer()
                Toggle("", isOn: binding)
            }
            .disabled(!isEditing)
            .foregroundStyle(isEditing ? .primary : .secondary)
            if useMovingAverage {
                HStack(spacing: 3) {
                    Stepper(
                        "",
                        value: daysBinding,
                        in: 2...7
                    )
                    .disabled(!isEditing)
                    .fixedSize()
                    Spacer()
                    Text("\(days)")
                        .contentTransition(.numericText(value: Double(days)))
                    Text("days")
                }
                .foregroundStyle(isEditing ? .primary : .secondary)
            }
        }
    }
}

#Preview("Current") {
    NavigationView {
        WeightChangePointForm()
    }
}

#Preview("Past") {
    NavigationView {
        WeightChangePointForm(pastDate: MockPastDate)
    }
}
