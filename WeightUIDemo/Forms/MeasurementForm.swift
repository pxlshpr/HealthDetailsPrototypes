import SwiftUI
import PrepShared
import SwiftUIIntrospect

struct MeasurementForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    
    @Environment(\.dismiss) var dismiss
    
    enum MeasurementType {
        case weight
        case height
        
        var name: String {
            switch self {
            case .weight:   "Weight"
            case .height:   "Height"
            }
        }
    }
    
    let type: MeasurementType
    let date: Date
    @State var time = Date.now
    
    @State var doubleInput = DoubleInput(automaticallySubmitsValues: true)
    @State var intInput = IntInput(automaticallySubmitsValues: true)
    
    @State var showingAlert = false
    @State var isDirty: Bool = false
    @State var dismissDisabled: Bool = false
    @State var hasFocusedOnAppear: Bool = false

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
    
    var unitString: String {
        switch type {
        case .height:   settingsProvider.heightUnit.abbreviation
        case .weight:   settingsProvider.bodyMassUnit.abbreviation
        }
    }

    var secondUnitString: String? {
        switch type {
        case .height:   settingsProvider.heightUnit.secondaryUnit
        case .weight:   settingsProvider.bodyMassUnit.secondaryUnit
        }
    }
    
    var customSection: some View {

        func introspect(_ textField: UITextField) {
            guard !hasFocusedOnAppear else { return }
            textField.becomeFirstResponder()
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
            hasFocusedOnAppear = true
        }
        func dualUnit(_ secondUnitString: String) -> some View {
            let firstComponent = Binding<String>(
                get: { intInput.binding.wrappedValue },
                set: { newValue in
                    intInput.binding.wrappedValue = newValue
                    setIsDirty()
                }
            )
            
            let secondComponent = Binding<String>(
                get: { doubleInput.binding.wrappedValue },
                set: { newValue in
                    doubleInput.binding.wrappedValue = newValue
                    guard let double = doubleInput.double else {
                        setIsDirty()
                        return
                    }
                    
                    switch type {
                    case .weight:
                        if double >= BodyMassUnit.upperSecondaryUnitValue {
                            doubleInput.binding.wrappedValue = ""
                        }
                    case .height:
                        if double >= HeightUnit.upperSecondaryUnitValue {
                            doubleInput.binding.wrappedValue = ""
                        }
                    }
                    setIsDirty()
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
        
        var singleUnit: some View {
            let firstComponent = Binding<String>(
                get: { doubleInput.binding.wrappedValue },
                set: { newValue in
                    doubleInput.binding.wrappedValue = newValue
                    setIsDirty()
                }
            )

            return HStack {
                Text(unitString)
                Spacer()
                TextField("", text: firstComponent)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .introspect(.textField, on: .iOS(.v17)) { introspect($0) }
            }
        }
        return Section {
            if let secondUnitString {
                dualUnit(secondUnitString)
            } else {
                singleUnit
            }
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
