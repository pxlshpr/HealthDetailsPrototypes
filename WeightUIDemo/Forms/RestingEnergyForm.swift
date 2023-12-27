import SwiftUI

struct RestingEnergyForm: View {

    @Environment(\.dismiss) var dismiss

    let isPast: Bool
    @State var isEditing: Bool

    @State var value: Double? = valueForActivityLevel(.lightlyActive)

    @State var source: RestingEnergySource = .equation
    @State var equation: RestingEnergyEquation = .mifflinStJeor
    
    @State var intervalType: HealthIntervalType = .average
    @State var interval: HealthInterval = .init(3, .day)

    @State var applyCorrection: Bool = true
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

    @State var showingEquationsInfo = false
    @State var showingHealthIntervalInfo = false
    
    init(isPast: Bool = false) {
        _isEditing = State(initialValue: isPast ? false : true)
        self.isPast = isPast
    }
    
    var body: some View {
        Form {
            explanation
            notice
            sourceSection
            switch source {
            case .userEntered:
                customSection
            case .equation:
                equationSection
                variablesSections
            case .healthKit:
                intervalTypeSection
                if intervalType == .average {
                    intervalSection
                }
                correctionSection
            }
        }
        .navigationTitle("Resting Energy")
        .toolbar { toolbarContent }
        .alert("Enter your Resting", isPresented: $showingAlert) {
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
        .sheet(isPresented: $showingEquationsInfo) { equationExplanations }
        .sheet(isPresented: $showingHealthIntervalInfo) {
            HealthIntervalInfo(isRestingEnergy: true)
        }
    }
    
    @ViewBuilder
    var notice: some View {
        if !isEditing {
            NoticeSection.legacy(MockPastDate)
        }
    }
    
    var correctionSection: some View {
        
        var footer: some View {
            var string: String {
                if applyCorrection, let correction {
                    switch correctionType {
                    case .divide:
                        "Your Resting Energy from Apple Health  being divided by \(correction.clean) before being used."
                    case .multiply:
                        "Your Resting Energy from Apple Health is being multiplied by \(correction.clean) before being used."
                    case .add:
                        "\(correction.clean) kcal is being added to your Resting Energy from Apple Health before being used."
                    case .subtract:
                        "\(correction.clean) kcal is being subtracted from your Resting Energy from Apple Health before being used."
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
            .disabled(isDisabled)
            .foregroundStyle(controlColor)
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
                .disabled(isDisabled)
                .foregroundStyle(controlColor)
            }
        }
        
        var correctionRow: some View {
            HStack {
                if let correction {
                    Group {
                        Text(correctionType.label)
                        Spacer()
                        Text(correction.clean)
                        if let unit = correctionType.unit {
                            Text(unit)
                        }
                    }
                    .foregroundStyle(controlColor)
                    if !isDisabled {
                        Button {
                            showingCorrectionAlert = true
                        } label: {
                            Image(systemName: "pencil")
                        }
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
                if correction != nil || !isDisabled {
                    correctionRow
                }
            }
        }
    }
    
    var equationSection: some View {
        let binding = Binding<RestingEnergyEquation>(
            get: { equation },
            set: { newValue in
                withAnimation {
                    equation = newValue
                }
            }
        )
        
        @ViewBuilder
        var footer: some View {
            if !isDisabled {
                Button {
                    showingEquationsInfo = true
                } label: {
                    Text("Learn more…")
                        .font(.footnote)
                }
            }
        }
        
        return Section(footer: footer) {
            Picker("Equation", selection: binding) {
                ForEach(RestingEnergyEquation.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.menu)
            .disabled(isDisabled)
            .foregroundStyle(controlColor)
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
    
    var isDisabled: Bool {
        isPast && !isEditing
    }
    
    var controlColor: Color {
        isDisabled ? .secondary : .primary
    }

    var sourceSection: some View {
        let binding = Binding<RestingEnergySource>(
            get: { source },
            set: { newValue in
                withAnimation {
                    source = newValue
                }
            }
        )
        
        return Section {
            Picker("Resting Energy", selection: binding) {
                ForEach(RestingEnergySource.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .foregroundStyle(controlColor)
            .pickerStyle(.menu)
        }
        .disabled(isDisabled)
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
        
        @ViewBuilder
        var footer: some View {
            if !isDisabled {
                Button {
                    showingHealthIntervalInfo = true
                } label: {
                    Text("Learn more…")
                        .font(.footnote)
                }
            }
        }

        return Section(footer: footer) {
            Picker("Use", selection: binding) {
                ForEach(HealthIntervalType.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.menu)
            .disabled(isDisabled)
            .foregroundStyle(controlColor)
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
            title: "Average of Previous",
            isDisabled: Binding<Bool>(
                get: { isDisabled },
                set: { _ in }
            )
        )
    }
    
    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Your Resting Energy, or your Basal Metabolic Rate (BMR), is the energy your body uses each day while minimally active. You can set it in three ways:")
                dotPoint("\"Apple Health\" uses the data recorded in the Health App.")
                dotPoint("\"Equation\" calculates it using your health details.")
                dotPoint("\"Custom\" allows you to enter the energy manually.")
            }
        }
    }

    var equationExplanations: some View {
        RestingEnergyEquationsInfo()
    }

    @ViewBuilder
    var customSection: some View {
        if !isDisabled {
            Section {
                Button {
                    showingAlert = true
                } label: {
                    Text("\(value != nil ? "Edit" : "Set") Resting Energy")
                }
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
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        if isPast {
                            withAnimation {
                                isEditing = false
                            }
                        } else {
                            dismiss()
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
                if isPast, isEditing {
                    Button("Cancel") {
                        withAnimation {
                            isEditing = false
                        }
                    }
                }
            }
        }
    }

    enum SexRoute {
        case form
    }
    
    enum AgeRoute {
        case form
    }
    
    enum HeightRoute {
        case form
    }
    
    enum WeightRoute {
        case form
    }

    var variablesSections: some View {
        var header: some View {
            Text("Variables")
//                .textCase(.none)
//                .font(.system(.title2, design: .rounded, weight: .semibold))
//                .foregroundStyle(Color(.label))
        }
        return Section(header: header) {
            NavigationLink(value: SexRoute.form) {
                HStack {
                    Text("Biological Sex")
                    Spacer()
                    Text("Male")
                }
            }
            .navigationDestination(for: SexRoute.self) { _ in
                if isPast {
                    
                } else {
                    SexForm()
                }
            }
            NavigationLink(value: AgeRoute.form) {
                HStack {
                    Text("Age")
                    Spacer()
                    Text("36 years")
                }
            }
            .navigationDestination(for: AgeRoute.self) { _ in
                AgeForm()
            }
            NavigationLink(value: HeightRoute.form) {
                HStack {
                    Text("Height")
                    Spacer()
                    Text("13 Jan 2017")
                        .foregroundStyle(.secondary)
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text("177 cm")
                }
            }
            .navigationDestination(for: HeightRoute.self) { _ in
                HeightForm(mode: .restingEnergyVariable(nil))
            }
            NavigationLink(value: WeightRoute.form) {
                HStack {
                    Text("Weight")
                    Spacer()
                    Text("18 Nov")
                        .foregroundStyle(.secondary)
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text("95.7 kg")
                }
            }
            .navigationDestination(for: WeightRoute.self) { _ in
                WeightForm()
            }
        }
    }
}

#Preview("Current") {
    NavigationView {
        RestingEnergyForm()
    }
}

#Preview("Past") {
    NavigationView {
        RestingEnergyForm(isPast: true)
    }
}
