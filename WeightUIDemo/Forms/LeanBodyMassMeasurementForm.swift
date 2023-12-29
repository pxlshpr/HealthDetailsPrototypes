import SwiftUI

struct LeanBodyMassMeasurementForm: View {
    
    @Environment(\.dismiss) var dismiss
    @State var source: LeanBodyMassSource = .fatPercentage
        
    @State var time = Date.now

    @State var equation: LeanBodyMassEquation = .boer
    @State var showingEquationsInfo = false
    
    @State var value: Double? = 72.0
    @State var customInput = DoubleInput(double: 72)
    @State var fatPercentageInput = DoubleInput(double: 24.8)
    
    @State var showingAlert = false
    @State var showingFatPercentageAlert = false

    let date: Date
    @State var isDirty: Bool = false

    @State var dismissDisabled: Bool = false
    
    init(date: Date? = nil) {
        self.date = (date ?? Date.now).startOfDay
    }

    var body: some View {
        NavigationView {
            form
                .navigationTitle("Lean Body Mass")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .safeAreaInset(edge: .bottom) { bottomValue }
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
        .interactiveDismissDisabled(dismissDisabled)
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    var form: some View {
        Form {
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
    
    func setDismissDisabled() {
        dismissDisabled = isDirty
    }
    
    var bottomValue: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            if let fatPercentage = fatPercentageInput.double {
                Text("\(fatPercentage.roundedToOnePlace)")
                    .contentTransition(.numericText(value: fatPercentage))
                    .font(LargeNumberFont)
                    .foregroundStyle(.primary)
                Text("% fat")
                    .font(LargeUnitFont)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let value {
                Text("\(value.roundedToOnePlace)")
                    .contentTransition(.numericText(value: value))
                    .font(LargeNumberFont)
                    .foregroundStyle(.primary)
                Text("kg")
                    .font(LargeUnitFont)
                    .foregroundStyle(.secondary)
            } else {
                ZStack {
                    
                    /// dummy text placed to ensure height stays consistent
                    Text("0")
                        .font(LargeNumberFont)
                        .opacity(0)

                    Text("Not Set")
                        .font(LargeUnitFont)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, BottomValueHorizontalPadding)
        .padding(.vertical, BottomValueVerticalPadding)
        .background(.bar)
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
        }
    }
    
    //MARK: - Sections
    var customSection: some View {
        InputSection(
            name: "Lean Body Mass",
            valueString: Binding<String?>(
                get: { customInput.double?.clean },
                set: { _ in }
            ),
            showingAlert: $showingAlert,
            unitString: "kcal",
            footerString: "The weight below will be used to calculate your Fat Percentage."
        )
    }
    
    var fatPercentageEnterSection: some View {
        InputSection(
            name: "Fat Percentage",
            valueString: Binding<String?>(
                get: { fatPercentageInput.double?.clean },
                set: { _ in }
            ),
            showingAlert: $showingFatPercentageAlert,
            unitString: "%",
            footerString: "The weight below will be used to calculate your Lean Body Mass."
        )
    }
    
    var weightSection: some View {
        EquationVariablesSections(
            healthDetails: Binding<[HealthDetail]>(
                get: { [.weight] },
                set: { _ in }
            ),
            pastDate: date,
            isEditing: .constant(false),
            isPresented: Binding<Bool>(
                get: { true },
                set: { newValue in
                    if !newValue {
                        dismiss()
                    }
                }
            ),
            dismissDisabled: $dismissDisabled,
            showHeader: false
        )
    }

    var equationVariablesSections: some View {
        EquationVariablesSections(
            healthDetails: Binding<[HealthDetail]>(
                get: { equation.requiredHealthDetails },
                set: { _ in }
            ),
            pastDate: date,
            isEditing: .constant(false),
            isPresented: Binding<Bool>(
                get: { true },
                set: { newValue in
                    if !newValue {
                        dismiss()
                    }
                }
            ),
            dismissDisabled: $dismissDisabled
        )
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
        
        var footer: some View {
            Button {
                showingEquationsInfo = true
            } label: {
                Text("Learn more…")
                    .font(.footnote)
            }
        }
        
        return Section(footer: footer) {
            Picker("Equation", selection: binding) {
                ForEach(LeanBodyMassEquation.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.menu)
        }
    }
    
    var dateTimeSection: some View {
        Section {
            DatePicker(
                "Date",
                selection: .constant(date),
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
    
    //MARK: - Actions
    
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

    func setIsDirty() {
        isDirty = if let value {
            value != 72
            || fatPercentageInput.double != 24.8
        } else {
            false
        }
    }
}


#Preview("Measurement") {
    LeanBodyMassMeasurementForm()
}
