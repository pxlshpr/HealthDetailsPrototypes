import SwiftUI

public extension Double {
    
    var roundedToOnePlace: String {
        /// round it off to a reasonable number first to avoid numbers like `7.00000000000009` resulting in `7.0`
        let value = self.rounded(toPlaces: 6).truncatingRemainder(dividingBy: 1)
        if value == 0 {
            return String(format: "%.0f", self.rounded(toPlaces: 1))
        } else {
            return String(self.rounded(toPlaces: 1))
        }
    }
}

struct LeanBodyMassMeasurementForm: View {
    
    @Environment(\.dismiss) var dismiss
    @State var source: LeanBodyMassSource = .fatPercentage
        
    @State var time = Date.now
    @State var date = Date.now

    @State var equation: LeanBodyMassEquation = .boer
    @State var showingEquationsInfo = false
    
    @State var value: Double? = 72.0
    @State var customInput = DoubleInput(double: 72)
    @State var fatPercentageInput = DoubleInput(double: 24.8)
    
    @State var showingAlert = false
    @State var showingFatPercentageAlert = false

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
        NavigationView {
            form
                .navigationTitle("Lean Body Mass")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
        }
        .alert("Enter your Lean Body Mass", isPresented: $showingAlert) {
            TextField("kg", text: customInput.binding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCustomValue)
            Button("Cancel") {
                customInput.cancel()
            }
        }
        .alert("Enter your Fat Percentage", isPresented: $showingFatPercentageAlert) {
            TextField("%", text: fatPercentageInput.binding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitFatPercentage)
            Button("Cancel") { 
                fatPercentageInput.cancel()
            }
        }
    }
    
    func submitCustomValue() {
        withAnimation {
            customInput.submitValue()
            value = customInput.double
            calculateFatPercentage(forLeanBodyMass: customInput.double)
            setIsDirty()
        }
    }

    func submitFatPercentage() {
        withAnimation {
            fatPercentageInput.submitValue()
            calculateLeanBodyMass(forFatPercentage: fatPercentageInput.double)
            setIsDirty()
        }
    }

    var form: some View {
        Form {
            notice
            dateTimeSection
            sourceSection
            switch source {
            case .equation:
                equationSection
                equationVariablesSections
            case .fatPercentage:
                fatPercentageEnterSection
                weightSection
            case .userEntered:
                customSection
                weightSection
            default:
                EmptyView()
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
                    Text("\(value != nil ? "Edit" : "Set") Lean Body Mass")
                }
            }
        }
    }
    
//    var customSection: some View {
//        CustomValueSection(
//            isDisabled: Binding<Bool>(
//                get: { isDisabled },
//                set: { _ in }
//            ),
//            value: Binding<Double?>(
//                get: { value },
//                set: { newValue in
//                    withAnimation {
//                        value = newValue
//                        calculateFatPercentage(forLeanBodyMass: newValue)
//                    }
//                }
//            ),
//            customValue: $customValue,
//            customValueTextAsDouble: $customValueTextAsDouble,
//            customValueText: $customValueText,
//            name: "Lean Body Mass",
//            unit: "kg",
//            setIsDirty: setIsDirty,
//            showingAlert: $showingAlert
//        )
//    }
    
    func calculateFatPercentage(forLeanBodyMass lbm: Double? = nil) {
        guard let lbm = lbm ?? self.value else {
            setFatPercentage(nil)
            return
        }
        let weight = 95.7
        let p = ((max(0, (weight - lbm)) / weight) * 100)
        setFatPercentage(p)
    }
    
    func calculateLeanBodyMass(forFatPercentage p: Double? = nil) {
        guard let p = p ?? self.fatPercentageInput.double else {
            setLeanBodyMass(nil)
            return
        }
        let weight = 95.7
        let lbm = weight - ((p / 100.0) * weight)
        setLeanBodyMass(lbm)
    }
    
    func setFatPercentage(_ p: Double?) {
        guard let p = p?.rounded(toPlaces: 1) else {
            fatPercentageInput = DoubleInput()
            return
        }
        fatPercentageInput = DoubleInput(double: p)
    }
    
    func setLeanBodyMass(_ lbm: Double?) {
        guard let lbm = lbm?.rounded(toPlaces: 1) else {
            value = nil
            customInput = DoubleInput()
            return
        }
        value = lbm
        customInput = DoubleInput(double: lbm)
    }
    
    @ViewBuilder
    var fatPercentageEnterSection: some View {
        if !isDisabled {
            Section {
                Button {
                    showingFatPercentageAlert = true
                } label: {
                    Text("\(value != nil ? "Edit" : "Set") Fat Percentage")
                }
            }
        }
    }
    
//    var fatPercentageEnterSection: some View {
//        CustomValueSection(
//            isDisabled: Binding<Bool>(
//                get: { isDisabled },
//                set: { _ in }
//            ),
//            value: Binding<Double?>(
//                get: { fatPercentage },
//                set: { newValue in
//                    withAnimation {
//                        fatPercentage = newValue
//                        calculateLeanBodyMass(forFatPercentage: newValue)
//                    }
//                }
//            ),
//            customValue: $fatPercentage,
//            customValueTextAsDouble: $fatPercentageTextAsDouble,
//            customValueText: $fatPercentageText,
//            name: "Fat Percentage",
//            unit: "%",
//            setIsDirty: setIsDirty,
//            showingAlert: $showingFatPercentageAlert
//        )
//    }
    
    var weightSection: some View {
        EquationVariablesSections(
            healthDetails: Binding<[HealthDetail]>(
                get: { [.weight] },
                set: { _ in }
            ),
            pastDate: pastDate,
            isEditing: $isEditing,
            isPresented: $isPresented,
            showHeader: false
        )
    }

    var equationVariablesSections: some View {
        EquationVariablesSections(
            healthDetails: Binding<[HealthDetail]>(
                get: { equation.requiredHealthDetails },
                set: { _ in }
            ),
            pastDate: pastDate,
            isEditing: $isEditing,
            isPresented: $isPresented
        )
    }
    
    func setIsDirty() {
        isDirty = if let value {
            value != 72
            || fatPercentageInput.double != 24.8
        } else {
            false
        }
    }
    
    var isDisabled: Bool {
        isPast && !isEditing
    }
    
    var controlColor: Color {
        isDisabled ? .secondary : .primary
    }
    
    var isPast: Bool {
        pastDate != nil
    }
    
    var equationSection: some View {
        let binding = Binding<LeanBodyMassEquation>(
            get: { equation },
            set: { newValue in
                withAnimation {
                    equation = newValue
                    calculateEquation()
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
                ForEach(LeanBodyMassEquation.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.menu)
            .disabled(isDisabled)
            .foregroundStyle(controlColor)
        }
    }
    
    var dateTimeSection: some View {
        Section {
            DatePicker(
                "Date",
                selection: $date,
                displayedComponents: .date
            )
            .disabled(true)
            DatePicker(
                "Time",
                selection: $time,
                displayedComponents: .hourAndMinute
            )
        }
    }
    
    func calculateEquation() {
        let weightInKg: Double? = 95.7
//        let heightInCm: Double? = 177
        let heightInCm: Double? = nil
        let sexIsFemale: Bool? = false
        
        let lbm: Double? = if let weightInKg, let heightInCm, let sexIsFemale {
            equation.calculateInKg(
                sexIsFemale: sexIsFemale,
                weightInKg: weightInKg,
                heightInCm: heightInCm
            )
        } else {
            nil
        }
        withAnimation {
            setLeanBodyMass(lbm)
            calculateFatPercentage()
        }
    }
    var sourceSection: some View {
        let binding = Binding<LeanBodyMassSource>(
            get: { source },
            set: { newValue in
                withAnimation {
                    source = newValue
//                    calculateEquation()
                    setIsDirty()
                }
                switch source {
                case .userEntered:
                    showingAlert = true
                case .fatPercentage:
                    showingFatPercentageAlert = true
                case .equation:
                    calculateEquation()
                default:
                    break
                }
            }
        )
        var picker: some View {
            Picker("Source", selection: binding) {
                ForEach(LeanBodyMassSource.formCases) { source in
                    Text(source.name).tag(source)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
        }
        
        var description: String {
            switch source {
            case .healthKit:
                ""
            case .equation:
                "Use an equation to calculate your Lean Body Mass."
            case .fatPercentage:
                "Use your fat percentage to calculate your Lean Body Mass."
            case .userEntered:
                "Enter your Lean Body Mass manually."
            }
        }
        return Section {
            picker
            Text(description)
        }
    }

    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: $isEditing)
        }
    }

    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add") {
                    dismiss()
                }
                .fontWeight(.bold)
                .disabled(!isDirty)
            }
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .bottomBar) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    if let fatPercentage = fatPercentageInput.double {
                        Text("\(fatPercentage.roundedToOnePlace)")
                            .contentTransition(.numericText(value: fatPercentage))
                            .font(LargeNumberFont)
                            .foregroundStyle(isDisabled ? .secondary : .primary)
                        Text("% fat")
                            .font(LargeUnitFont)
                            .foregroundStyle(isDisabled ? .tertiary : .secondary)
                    }
                    Spacer()
                    if let value {
                        Text("\(value.roundedToOnePlace)")
                            .contentTransition(.numericText(value: value))
                            .font(LargeNumberFont)
                            .foregroundStyle(isDisabled ? .secondary : .primary)
                        Text("kg")
                            .font(LargeUnitFont)
                            .foregroundStyle(isDisabled ? .tertiary : .secondary)
                    } else {
                        Text("Not Set")
                            .font(LargeUnitFont)
                            .foregroundStyle(isDisabled ? .tertiary : .secondary)
                    }
                }
            }
//            topToolbarContent(
//                isEditing: $isEditing,
//                isDirty: $isDirty,
//                isPast: isPast,
//                dismissAction: { isPresented = false },
//                undoAction: undo,
//                saveAction: save
//            )
        }
    }
}


#Preview("Measurement (Current)") {
    LeanBodyMassMeasurementForm()
}

#Preview("Measurement (Past)") {
    LeanBodyMassMeasurementForm(pastDate: MockPastDate)
}
