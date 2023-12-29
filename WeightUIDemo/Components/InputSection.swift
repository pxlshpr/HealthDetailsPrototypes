import SwiftUI

struct InputSection: View {
    
    let name: String
    @Binding var valueString: String?
    @Binding var showingAlert: Bool
    @Binding var isDisabled: Bool
    let unitString: String
    let footerString: String?

    init(
        name: String,
        valueString: Binding<String?>,
        showingAlert: Binding<Bool>,
        isDisabled: Binding<Bool> = .constant(false),
        unitString: String,
        footerString: String? = nil
    ) {
        self.name = name
        self.footerString = footerString
        _valueString = valueString
        _showingAlert = showingAlert
        _isDisabled = isDisabled
        self.unitString = unitString
    }
    
    var body: some View {
        Section(footer: footer) {
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
    
    @ViewBuilder
    var footer: some View {
        if let footerString {
            Text(footerString)
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
