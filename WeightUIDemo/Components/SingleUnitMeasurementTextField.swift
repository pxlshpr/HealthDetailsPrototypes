import SwiftUI

struct SingleUnitMeasurementTextField: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    
    let type: MeasurementType
    let footerString: String?

    @Binding var doubleInput: DoubleInput
    @Binding var hasFocused: Bool
    @Binding var focusDelay: Double
    let delayFocus: Bool
    let handleChanges: () -> ()

    init(
        type: MeasurementType,
        doubleInput: Binding<DoubleInput>,
        hasFocused: Binding<Bool>,
        delayFocus: Bool = false,
        focusDelay: Binding<Double> = .constant(0.05),
        footer: String? = nil,
        handleChanges: @escaping () -> Void
    ) {
        self.type = type
        _focusDelay = focusDelay
        _doubleInput = doubleInput
        _hasFocused = hasFocused
        self.delayFocus = delayFocus
        self.footerString = footer
        self.handleChanges = handleChanges
    }
    
    var body: some View {
        Section(footer: footer) {
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
    
    @ViewBuilder
    var footer: some View {
        if let footerString {
            Text(footerString)
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

        let deadline: DispatchTime = .now() + (delayFocus ? focusDelay : 0)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            textField.becomeFirstResponder()
            textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
        }
    }
}

