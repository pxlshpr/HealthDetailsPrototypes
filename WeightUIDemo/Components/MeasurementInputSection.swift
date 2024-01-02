import SwiftUI
import PrepShared

struct MeasurementInputSection: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    
    let type: MeasurementType

    @Binding var doubleInput: DoubleInput
    @Binding var intInput: IntInput
    @Binding var hasFocused: Bool
    @Binding var focusDelay: Double
    let delayFocus: Bool
    let footerString: String?
    let handleChanges: () -> ()

    init(
        type: MeasurementType,
        doubleInput: Binding<DoubleInput>,
        intInput: Binding<IntInput>,
        hasFocused: Binding<Bool>,
        delayFocus: Bool = false,
        focusDelay: Binding<Double> = .constant(0.05),
        footer: String? = nil,
        handleChanges: @escaping () -> Void
    ) {
        self.type = type
        _focusDelay = focusDelay
        _doubleInput = doubleInput
        _intInput = intInput
        _hasFocused = hasFocused
        self.delayFocus = delayFocus
        self.footerString = footer
        self.handleChanges = handleChanges
    }
    
    @ViewBuilder
    var body: some View {
        if let secondUnitString {
            Section(footer: footer) {
                dualUnit(secondUnitString)
            }
        } else {
            singleUnit
        }
    }
    
    @ViewBuilder
    var footer: some View {
        if let footerString {
            Text(footerString)
        }
    }
    
    var singleUnit: some View {
        SingleUnitMeasurementTextField(
            type: type,
            doubleInput: $doubleInput,
            hasFocused: $hasFocused,
            delayFocus: delayFocus,
            focusDelay: $focusDelay,
            footer: footerString,
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

        let deadline: DispatchTime = .now() + (delayFocus ? focusDelay : 0)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            textField.becomeFirstResponder()
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
        }
    }
}
