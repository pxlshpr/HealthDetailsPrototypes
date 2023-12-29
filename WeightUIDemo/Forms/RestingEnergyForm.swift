import SwiftUI

struct RestingEnergyForm: View {

    @Environment(\.dismiss) var dismiss

    @State var value: Double? = 2798

    @State var source: RestingEnergySource = .healthKit
    @State var equation: RestingEnergyEquation = .mifflinStJeor
    
    @State var intervalType: HealthIntervalType = .average
    @State var interval: HealthInterval = .init(3, .day)

    @State var applyCorrection: Bool = true
    @State var correctionType: CorrectionType = .divide
    @State var correction: Double? = 2

    @State var showingAlert = false
    
    @State var correctionTextAsDouble: Double? = 2
    @State var correctionText: String = "2"

    @State var showingEquationsInfo = false
    @State var showingRestingEnergyInfo = false

    @State var customInput = DoubleInput(double: 2798)
    
    let pastDate: Date?
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool

    init(pastDate: Date? = nil, isPresented: Binding<Bool> = .constant(true)) {
        self.pastDate = pastDate
        _isPresented = isPresented
        _isEditing = State(initialValue: pastDate == nil)
    }

    var body: some View {
        Form {
            notice
            explanation
            sourceSection
            switch source {
            case .userEntered:
                customSection
//                EmptyView()
            case .equation:
                equationSection
                variablesSections
            case .healthKit:
                healthSections
            }
        }
        .navigationTitle("Resting Energy")
        .navigationBarBackButtonHidden(isEditing && isPast)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingEquationsInfo) { equationExplanations }
        .sheet(isPresented: $showingRestingEnergyInfo) {
            RestingEnergyInfo()
        }
        .alert("Enter your Resting Energy", isPresented: $showingAlert) {
            TextField("kcal", text: customInput.binding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCustomValue)
            Button("Cancel") { }
        }
    }
    
//    var customValueTextBinding: Binding<String> {
//        Binding<String>(
//            get: { customValueText },
//            set: { newValue in
//                /// Cleanup by removing any extra periods and non-numbers
//                let newValue = newValue.sanitizedDouble
//                customValueText = newValue
//                
//                /// If we haven't already set the flag for the trailing period, and the string has period as its last character, set it so that its displayed
//                if !includeTrailingPeriod, newValue.last == "." {
//                    includeTrailingPeriod = true
//                }
//                /// If we have set the flag for the trailing period and the last character isn't it—unset it
//                else if includeTrailingPeriod, newValue.last != "." {
//                    includeTrailingPeriod = false
//                }
//                
//                if newValue == ".0" {
//                    includeTrailingZero = true
//                } else {
//                    includeTrailingZero = false
//                }
//                
//                let double = Double(newValue)
//                customValueTextAsDouble = double
//                
////                customValueText = if let customValueTextAsDouble {
////                    "\(customValueTextAsDouble)"
////                } else {
////                    ""
////                }
//            }
//        )
//    }
    
//    func submitCustomValue() {
//        withAnimation {
//            customValue = customValueTextAsDouble
//            value = customValue
//            setIsDirty()
//        }
//    }

    func submitCustomValue() {
        withAnimation {
            customInput.submitValue()
            value = customInput.double
            setIsDirty()
        }
    }

    var toolbarContent: some ToolbarContent {
        Group {
            bottomToolbarContent(
                value: value,
                valueString: value?.formattedEnergy,
                isDisabled: !isEditing,
                unitString: "kcal"
            )
            topToolbarContent(
                isEditing: $isEditing,
                isDirty: $isDirty,
                isPast: isPast,
                dismissAction: { isPresented = false },
                undoAction: undo,
                saveAction: save
            )
        }
    }
    
    var equationExplanations: some View {
        RestingEnergyEquationsInfo()
    }
}

//MARK: - Sections

extension RestingEnergyForm {
    
    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: $isEditing)
        }
    }
    
    var sourceSection: some View {
        let binding = Binding<RestingEnergySource>(
            get: { source },
            set: { newValue in
                withAnimation {
                    source = newValue
                    setIsDirty()
                }
                if source == .userEntered {
                    showingAlert = true
                }
            }
        )
        
        var pickerSection: some View {
            Section {
                Picker("Resting Energy", selection: binding) {
                    ForEach(RestingEnergySource.allCases, id: \.self) {
                        Text($0.name).tag($0)
                    }
                }
                .foregroundStyle(controlColor)
                .pickerStyle(.segmented)
                .listRowBackground(EmptyView())
            }
            .disabled(isDisabled)
            .listSectionSpacing(.compact)
        }
        
        var descriptionSection: some View {
            var description: String {
                switch source {
                case .healthKit:
                    "Use the Resting Energy data recorded in the Apple Health app."
                case .equation:
                    "Use an equation to calculate your Resting Energy."
                case .userEntered:
                    "Enter the Resting Energy manually."
                }
            }
            
            return Section {
                Text(description)
            }
        }
        
        return Group {
            pickerSection
            descriptionSection
        }
    }
    
    var healthSections: some View {
        EnergyAppleHealthSections(
            intervalType: $intervalType,
            interval: $interval,
            pastDate: pastDate,
            isEditing: $isEditing,
            applyCorrection: $applyCorrection,
            correctionType: $correctionType,
            correction: $correction,
            correctionTextAsDouble: $correctionTextAsDouble,
            correctionText: $correctionText,
            setIsDirty: setIsDirty,
            isRestingEnergy: true
        )
    }

    var explanation: some View {
        var header: some View {
            Text("About Resting Energy")
                .textCase(.none)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(Color(.label))
        }
        
        var footer: some View {
            Button {
                showingRestingEnergyInfo = true
            } label: {
                Text("Learn more…")
                    .font(.footnote)
            }
        }
        
        return Section {
            VStack(alignment: .leading) {
                Text("Your Resting Energy, or your Basal Metabolic Rate (BMR), is the energy your body uses each day while minimally active. You can set it in three ways.")
            }
        }
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
    
    var equationSection: some View {
        let binding = Binding<RestingEnergyEquation>(
            get: { equation },
            set: { newValue in
                withAnimation {
                    equation = newValue
                    setIsDirty()
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
}

//MARK: - Convenience

extension RestingEnergyForm {
    var isDisabled: Bool {
        isPast && !isEditing
    }
    
    var controlColor: Color {
        isDisabled ? .secondary : .primary
    }
    
    var isPast: Bool {
        pastDate != nil
    }
}

//MARK: - Actions

extension RestingEnergyForm {
    func undo() {
        isDirty = false
        source = .equation
        equation = .mifflinStJeor
        intervalType = .average
        interval = .init(3, .day)
        applyCorrection = true
        correctionType = .divide
        correction = 2
        value = 2798
        customInput = DoubleInput(double: 2798)
        correctionTextAsDouble = 2
        correctionText = "2"
    }
    
    func setIsDirty() {
        isDirty = source != .equation
        || equation != .mifflinStJeor
        || intervalType != .average
        || interval != .init(3, .day)
        || applyCorrection != true
        || correctionType != .divide
        || correction != 2
        || value != 2798
        || correctionTextAsDouble != 2
        || correctionText != "2"
    }
    
    func save() {
        
    }
}

//MARK: - Previews

#Preview("Current") {
    NavigationView {
        RestingEnergyForm()
    }
}

#Preview("Past") {
    NavigationView {
        RestingEnergyForm(pastDate: MockPastDate)
    }
}
