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
    
    init(type: MeasurementType, date: Date? = nil) {
        self.date = (date ?? Date.now).startOfDay
        self.type = type
    }
    
    var body: some View {
        NavigationView {
            form
                .navigationTitle(type.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
            //                .safeAreaInset(edge: .bottom) { bottomValue }
        }
        .interactiveDismissDisabled(dismissDisabled)
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
//        .onAppear {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//                isFocused = true
//            }
//        }
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
    
//    @FocusState var isFocused: Bool
    
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
//                        .focused($isFocused)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .introspect(.textField, on: .iOS(.v17)) { textField in
                            textField.becomeFirstResponder()
                        }
                }
                HStack {
                    Text(secondUnitString)
                    Spacer()
                    TextField("", text: secondComponent)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .introspect(.textField, on: .iOS(.v17)) { textField in
                            textField.becomeFirstResponder()
                        }
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
//                    .focused($isFocused)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
        }
        return Section {
            if let secondUnitString {
                dualUnit(secondUnitString)
            } else {
                singleUnit
            }
        }
        //        InputSection(
        //            name: settingsProvider.heightUnit.abbreviation,
        //            valueString: Binding<String?>(
        //                get: { customInput.double?.clean },
        //                set: { _ in }
        //            ),
        //            showingAlert: $showingAlert,
        //            unitString: unitString
        //        )
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
    MeasurementForm(type: .height)
        .environment(SettingsProvider(settings: .init(heightUnit: .cm)))
}

#Preview("Height (ft)") {
    MeasurementForm(type: .height)
        .environment(SettingsProvider(settings: .init(heightUnit: .ft)))
}

#Preview("HeightForm") {
    NavigationView {
        HeightForm(healthProvider: MockCurrentProvider)
            .environment(SettingsProvider(settings: .init(heightUnit: .ft)))
    }
}

extension HeightUnit {
    var secondaryUnit: String? {
        hasTwoComponents ? "in" : nil
    }
    
    static var upperSecondaryUnitValue: Double {
        /// 12 inches equal 1 feet
        12
    }
}

extension BodyMassUnit {
    var secondaryUnit: String? {
        hasTwoComponents ? "lb" : nil
    }
    
    static var upperSecondaryUnitValue: Double {
        /// 14 pounds equals 1 stone
        14
    }
}
