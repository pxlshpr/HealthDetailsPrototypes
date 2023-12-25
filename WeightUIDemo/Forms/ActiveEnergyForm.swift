import SwiftUI

struct ActiveEnergyForm: View {

    @Environment(\.dismiss) var dismiss

    @State var value: Double? = valueForActivityLevel(.lightlyActive)
    @State var source: ActiveEnergySource = .activityLevel
    @State var activityLevel: ActivityLevel = .lightlyActive
    @State var intervalType: HealthIntervalType = .average
    @State var interval: HealthInterval = .init(3, .day)
    @State var applyCorrection: Bool = false
    @State var correctionType: CorrectionType = .divide
    @State var correction: Double? = nil

    @State var showingAlert = false
    @State var customValue: Double? = nil
    @State var customValueTextAsDouble: Double? = nil
    @State var customValueText: String = ""
    
    @State var includeTrailingPeriod: Bool = false
    @State var includeTrailingZero: Bool = false
    @State var numberOfTrailingZeros: Int = 0

    @State var showingCorrectionAlert = false
    @State var correctionTextAsDouble: Double? = nil
    @State var correctionText: String = ""

    @State var showingHealthIntervalInfo = false
    @State var showingActivityLevelInfo = false

    var body: some View {
        Form {
            explanation
            sourceSection
            switch source {
            case .userEntered:
                customSection
            case .activityLevel:
                activityLevelSection
            case .healthKit:
                intervalTypeSection
                if intervalType == .average {
                    intervalSection
                }
                correctionSection
            }
        }
        .navigationTitle("Active Energy")
        .toolbar { toolbarContent }
        .alert("Enter your Active Energy", isPresented: $showingAlert) {
            TextField("kcal", text: customValueTextBinding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCustomValue)
            Button("Cancel") { }
        }
        .alert("Enter a correction", isPresented: $showingCorrectionAlert) {
            TextField(correctionType.textFieldPlaceholder, text: correctionTextBinding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCorrection)
            Button("Cancel") { }
        }
        .sheet(isPresented: $showingHealthIntervalInfo) {
            HealthIntervalInfo(isRestingEnergy: false)
        }
        .sheet(isPresented: $showingActivityLevelInfo) {
            ActivityLevelInfo()
        }
    }
    
    var correctionSection: some View {
        
        var footer: some View {
            var string: String {
                if applyCorrection, let correction {
                    switch correctionType {
                    case .divide:
                        "Your Active Energy from Apple Health is being divided by \(correction.clean) before being used."
                    case .multiply:
                        "Your Active Energy from Apple Health is being multiplied by \(correction.clean) before being used."
                    case .add:
                        "\(correction.clean) kcal is being added to your Active Energy from Apple Health before being used."
                    case .subtract:
                        "\(correction.clean) kcal is being subtracted from your Active Energy from Apple Health before being used."
                    }
                } else {
                    "If you have reason to believe that the data from Apple Health may be inaccurate, use a correction to account for this."
                }
            }
            
            return Text(string)
        }
        
        var toggleRow: some View {
            let binding = Binding<Bool>(
                get: { applyCorrection },
                set: { newValue in
                    withAnimation {
                        applyCorrection = newValue
                    }
                }
            )
            return HStack {
                Text("Apply Correction")
                Spacer()
                Toggle("", isOn: binding)
            }
        }
        
        var correctionTypeRow: some View {
            let binding = Binding<CorrectionType>(
                get: { correctionType },
                set: { newValue in
                    withAnimation {
                        correctionType = newValue
//                        value = valueForActivityLevel(newValue)
                    }
                }
            )
            return Section {
                Picker("Type", selection: binding) {
                    ForEach(CorrectionType.allCases, id: \.self) {
                        Text($0.name).tag($0)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        
        var correctionRow: some View {
            HStack {
                if let correction {
                    Text(correctionType.label)
                    Spacer()
                    Text(correction.clean)
                    if let unit = correctionType.unit {
                        Text(unit)
                    }
                    Button {
                        showingCorrectionAlert = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                } else {
                    Button("Set Correction") {
                        showingCorrectionAlert = true
                    }
                }
            }
        }
        
        return Section(header: Text("Correction"), footer: footer) {
            toggleRow
            if applyCorrection {
                correctionTypeRow
                correctionRow
            }
        }
    }
    var activityLevelSection: some View {
        let binding = Binding<ActivityLevel>(
            get: { activityLevel },
            set: { newValue in
                withAnimation {
                    activityLevel = newValue
                    value = valueForActivityLevel(newValue)
                }
            }
        )
        
        var footer: some View {
            Button {
                showingActivityLevelInfo = true
            } label: {
                Text("Learn more…")
                    .font(.footnote)
            }
        }

        return Section(footer: footer) {
            Picker("Activity Level", selection: binding) {
                ForEach(ActivityLevel.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    var customValueTextBinding: Binding<String> {
        Binding<String>(
            get: { customValueText },
            set: { newValue in
                /// Cleanup by removing any extra periods and non-numbers
                let newValue = newValue.sanitizedDouble
                customValueText = newValue
                
                /// If we haven't already set the flag for the trailing period, and the string has period as its last character, set it so that its displayed
                if !includeTrailingPeriod, newValue.last == "." {
                    includeTrailingPeriod = true
                }
                /// If we have set the flag for the trailing period and the last character isn't it—unset it
                else if includeTrailingPeriod, newValue.last != "." {
                    includeTrailingPeriod = false
                }
                
                if newValue == ".0" {
                    includeTrailingZero = true
                } else {
                    includeTrailingZero = false
                }
                
                let double = Double(newValue)
                customValueTextAsDouble = double
                
//                customValueText = if let customValueTextAsDouble {
//                    "\(customValueTextAsDouble)"
//                } else {
//                    ""
//                }
            }
        )
    }
    
    var correctionTextBinding: Binding<String> {
        Binding<String>(
            get: { correctionText },
            set: { newValue in
                /// Cleanup by removing any extra periods and non-numbers
                let newValue = newValue.sanitizedDouble
                correctionText = newValue
                
                /// If we haven't already set the flag for the trailing period, and the string has period as its last character, set it so that its displayed
                if !includeTrailingPeriod, newValue.last == "." {
                    includeTrailingPeriod = true
                }
                /// If we have set the flag for the trailing period and the last character isn't it—unset it
                else if includeTrailingPeriod, newValue.last != "." {
                    includeTrailingPeriod = false
                }
                
                if newValue == ".0" {
                    includeTrailingZero = true
                } else {
                    includeTrailingZero = false
                }
                
                let double = Double(newValue)
                correctionTextAsDouble = double

//                customValueText = if let customValueTextAsDouble {
//                    "\(customValueTextAsDouble)"
//                } else {
//                    ""
//                }
            }
        )
    }
    
    func submitCustomValue() {
        withAnimation {
            customValue = customValueTextAsDouble
            value = customValue
        }
    }

    func submitCorrection() {
        withAnimation {
            correction = correctionTextAsDouble
        }
    }

    var sourceSection: some View {
        let binding = Binding<ActiveEnergySource>(
            get: { source },
            set: { newValue in
                withAnimation {
                    source = newValue
                }
            }
        )
        return Section {
            Picker("Active Energy", selection: binding) {
                ForEach(ActiveEnergySource.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    var intervalTypeSection: some View {
        let binding = Binding<HealthIntervalType>(
            get: { intervalType },
            set: { newValue in
                withAnimation {
                    intervalType = newValue
                }
            }
        )
        
        var footer: some View {
            Button {
                showingHealthIntervalInfo = true
            } label: {
                Text("Learn more…")
                    .font(.footnote)
            }
        }

        return Section(footer: footer) {
            Picker("Use", selection: binding) {
                ForEach(HealthIntervalType.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    var intervalSection: some View {
        var binding: Binding<HealthInterval> {
            Binding<HealthInterval>(
                get: { interval },
                set: { newValue in
                    withAnimation {
                        interval = newValue
                    }
                }
            )
        }

        return IntervalPicker(
            interval: binding,
            periods: [.day, .week],
            ranges: [.week: 1...2],
            title: "Average of Previous"
        )
    }
    
    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("This is the energy burnt over and above your Resting Energy use. You can set it in three ways:")
                dotPoint("\"Apple Health\" uses the data recorded in the Health App.")
                dotPoint("\"Activity Level\" uses a multiplier on your Resting energy based on how active you are.")
                dotPoint("\"Custom\" allows you to enter the energy manually.")
            }
        }
    }

    var customSection: some View {
        Section {
            Button {
                showingAlert = true
            } label: {
                Text("\(value != nil ? "Edit" : "Set") Active Energy")
            }
        }
    }

    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .bottomBar) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Spacer()
                    if let value {
                        Text("\(value.formattedEnergy)")
                            .contentTransition(.numericText(value: value))
                            .font(LargeNumberFont)
                        Text("kcal")
                            .font(LargeUnitFont)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not Set")
                            .font(LargeUnitFont)
                            .foregroundStyle(.secondary)
                    }
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

}

#Preview {
    ActiveEnergyForm()
}

func valueForActivityLevel(_ activityLevel: ActivityLevel) -> Double {
    switch activityLevel {
    case .sedentary:            2442
    case .lightlyActive:        2798.125
    case .moderatelyActive:     3154.25
    case .active:               3510.375
    case .veryActive:           3866.5
    }
}

enum CorrectionType: CaseIterable {
    case add
    case subtract
    case multiply
    case divide
    
    var name: String {
        switch self {
        case .add:      "Add"
        case .subtract: "Subtract"
        case .multiply: "Multiply"
        case .divide:   "Divide"
        }
    }
    
    var label: String {
        switch self {
        case .add:      "Add"
        case .subtract: "Subtract"
        case .multiply: "Multiply by"
        case .divide:   "Divide by"
        }
    }
    
    var symbol: String {
        switch self {
        case .add:      "+"
        case .subtract: "-"
        case .multiply: "×"
        case .divide:   "÷"
        }
    }
    
    var textFieldPlaceholder: String {
        switch self {
        case .add:      "kcal to add"
        case .subtract: "kcal to subtract"
        case .multiply: "Multiply by"
        case .divide:   "Divide by"
        }
    }
    
    var unit: String? {
        switch self {
        case .add:      "kcal"
        case .subtract: "kcal"
        case .multiply: nil
        case .divide:   nil
        }
    }
}

func dotPoint(_ string: String) -> some View {
    Label {
        Text(string)
    } icon: {
        Circle()
            .foregroundStyle(Color(.label))
            .frame(width: 5, height: 5)
    }
}
