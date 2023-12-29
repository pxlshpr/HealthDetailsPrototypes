import SwiftUI

struct InputSection: View {
    
    let name: String
    @Binding var valueString: String?
    @Binding var showingAlert: Bool
    @Binding var isDisabled: Bool
    let unitString: String

    init(
        name: String,
        valueString: Binding<String?>,
        showingAlert: Binding<Bool>,
        isDisabled: Binding<Bool> = .constant(false),
        unitString: String
    ) {
        self.name = name
        _valueString = valueString
        _showingAlert = showingAlert
        _isDisabled = isDisabled
        self.unitString = unitString
    }
    
    var body: some View {
        Section {
            if let valueString {
                HStack {
                    Text(name)
                    Spacer()
                    Text("\(valueString) \(unitString)")
                        .foregroundStyle(isDisabled ? .secondary : .primary)
                    if !isDisabled {
                        Button {
                            showingAlert = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                }
            } else {
                addButton
            }
        }
    }
    
    var addButton: some View {
        Button {
            showingAlert = true
        } label: {
            Text("\(valueString != nil ? "Edit" : "Set") \(name)")
        }
    }
}
