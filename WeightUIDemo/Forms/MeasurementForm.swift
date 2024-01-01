import SwiftUI
import PrepShared
import SwiftUIIntrospect

struct MeasurementForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    @Environment(\.dismiss) var dismiss
    
    let type: MeasurementType
    let date: Date
    @State var time = Date.now
    
    @State var doubleInput = DoubleInput(automaticallySubmitsValues: true)
    @State var intInput = IntInput(automaticallySubmitsValues: true)
    
    @State var isDirty: Bool = false
    @State var dismissDisabled: Bool = false
    @State var hasFocusedCustom: Bool = false

    let add: (Int, Double, Date) -> ()
    
    init(
        type: MeasurementType,
        date: Date? = nil,
        add: @escaping (Int, Double, Date) -> ()
    ) {
        self.date = (date ?? Date.now).startOfDay
        self.type = type
        self.add = add
    }
    
    var body: some View {
        NavigationView {
            form
                .navigationTitle(type.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
        }
        .interactiveDismissDisabled(dismissDisabled)
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    var form: some View {
        Form {
            dateTimeSection
            customSection
        }
    }
    
    func setDismissDisabled() {
        dismissDisabled = isDirty
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add") {
                    add(intInput.int ?? 0, doubleInput.double ?? 0, time)
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
    
    func setIsDirty() {
        isDirty = !(doubleInput.double == nil && intInput.int == nil)
    }
    
    //MARK: - Sections

    var customSection: some View {
        MeasurementTextField(
            type: type,
            doubleInput: $doubleInput,
            intInput: $intInput,
            hasFocused: $hasFocusedCustom,
            handleChanges: setIsDirty
        )
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
}

#Preview("Height (cm)") {
    MeasurementForm(type: .height) { int, double, time in
        
    }
    .environment(SettingsProvider(settings: .init(heightUnit: .cm)))
}

#Preview("Height (ft)") {
    MeasurementForm(type: .height) { int, double, time in
        
    }
    .environment(SettingsProvider(settings: .init(heightUnit: .ft)))
}

#Preview("HeightForm") {
    NavigationView {
        HeightForm(healthProvider: MockCurrentProvider)
            .environment(SettingsProvider(settings: .init(heightUnit: .ft)))
    }
}

struct MeasurementTextField: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    
    let type: MeasurementType

    @Binding var doubleInput: DoubleInput
    @Binding var intInput: IntInput
    @Binding var hasFocused: Bool
    let delayFocus: Bool
    let handleChanges: () -> ()

    init(
        type: MeasurementType,
        doubleInput: Binding<DoubleInput>,
        intInput: Binding<IntInput>,
        hasFocused: Binding<Bool>,
        delayFocus: Bool = false,
        handleChanges: @escaping () -> Void
    ) {
        self.type = type
        _doubleInput = doubleInput
        _intInput = intInput
        _hasFocused = hasFocused
        self.delayFocus = delayFocus
        self.handleChanges = handleChanges
    }
    
    var body: some View {
        Section {
            if let secondUnitString {
                dualUnit(secondUnitString)
            } else {
                singleUnit
            }
        }
    }
    
    var singleUnit: some View {
        SingleUnitMeasurementTextField(
            type: type,
            doubleInput: $doubleInput,
            hasFocused: $hasFocused,
            delayFocus: delayFocus,
            handleChanges: handleChanges
        )
    }
    
    func dualUnit(_ secondUnitString: String) -> some View {
        let firstComponent = Binding<String>(
            get: { intInput.binding.wrappedValue },
            set: { newValue in
                intInput.binding.wrappedValue = newValue
                handleChanges()
            }
        )
        
        let secondComponent = Binding<String>(
            get: { doubleInput.binding.wrappedValue },
            set: { newValue in
                doubleInput.binding.wrappedValue = newValue
                guard let double = doubleInput.double else {
                    handleChanges()
                    return
                }
                
                switch type {
                case .weight, .leanBodyMass:
                    if double >= BodyMassUnit.upperSecondaryUnitValue {
                        doubleInput.binding.wrappedValue = ""
                    }
                case .height:
                    if double >= HeightUnit.upperSecondaryUnitValue {
                        doubleInput.binding.wrappedValue = ""
                    }
                default:
                    break
                }
                handleChanges()
            }
        )
        return Group {
            HStack {
                Text(unitString)
                Spacer()
                TextField("", text: firstComponent)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .introspect(.textField, on: .iOS(.v17)) { introspect($0) }
            }
            HStack {
                Text(secondUnitString)
                Spacer()
                TextField("", text: secondComponent)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    var unitString: String {
        settingsProvider.unitString(for: type)
    }

    var secondUnitString: String? {
        settingsProvider.secondUnitString(for: type)
    }
    
    func introspect(_ textField: UITextField) {
        guard !hasFocused else { return }
        
        /// Set this immediately
        hasFocused = true

        print("⌨️ Making textField first responder")
        let deadline: DispatchTime = .now() + (delayFocus ? 0.05 : 0)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            textField.becomeFirstResponder()
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
        }
    }
    
}

struct SingleUnitMeasurementTextField: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    
    let type: MeasurementType

    @Binding var doubleInput: DoubleInput
    @Binding var hasFocused: Bool
    let delayFocus: Bool
    let handleChanges: () -> ()

    init(
        type: MeasurementType,
        doubleInput: Binding<DoubleInput>,
        hasFocused: Binding<Bool>,
        delayFocus: Bool = false,
        handleChanges: @escaping () -> Void
    ) {
        self.type = type
        _doubleInput = doubleInput
        _hasFocused = hasFocused
        self.delayFocus = delayFocus
        self.handleChanges = handleChanges
    }
    
    var body: some View {
        Section {
            HStack {
                Text(unitString)
                Spacer()
                TextField("", text: binding)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .introspect(.textField, on: .iOS(.v17)) { introspect($0) }
            }
        }
    }
    
    var binding: Binding<String> {
        Binding<String>(
            get: { doubleInput.binding.wrappedValue },
            set: { newValue in
                doubleInput.binding.wrappedValue = newValue
                handleChanges()
            }
        )
    }
    
    var unitString: String {
        settingsProvider.unitString(for: type)
    }

    func introspect(_ textField: UITextField) {
        guard !hasFocused else { return }
        hasFocused = true

        let deadline: DispatchTime = .now() + (delayFocus ? 0.05 : 0)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            textField.becomeFirstResponder()
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
        }
    }
}
