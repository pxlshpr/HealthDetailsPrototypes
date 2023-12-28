import SwiftUI

struct EnergyCustomSection: View {
    
    @Binding var isDisabled: Bool
    @Binding var value: Double?

    @Binding var customValue: Double?
    @Binding var customValueTextAsDouble: Double?
    @Binding var customValueText: String

    let isRestingEnergy: Bool
    let setIsDirty: () -> ()

    @Binding var  showingAlert: Bool

    @State var includeTrailingPeriod: Bool = false
    @State var includeTrailingZero: Bool = false
    @State var numberOfTrailingZeros: Int = 0

    var body: some View {
        customSection
            .alert("Enter your \(name)", isPresented: $showingAlert) {
                TextField("kcal", text: customValueTextBinding)
                    .keyboardType(.decimalPad)
                Button("OK", action: submitCustomValue)
                Button("Cancel") { }
            }
    }
    
    var name: String {
        isRestingEnergy ? "Resting Energy" : "Active Energy"
    }

    func submitCustomValue() {
        withAnimation {
            customValue = customValueTextAsDouble
            value = customValue
            setIsDirty()
        }
    }

    @ViewBuilder
    var customSection: some View {
        if !isDisabled {
            Section {
                Button {
                    showingAlert = true
                } label: {
                    Text("\(value != nil ? "Edit" : "Set") \(name)")
                }
            }
        }
    }
    
    var customValueTextBinding: Binding<String> {
        Binding<String>(
            get: { customValueText },
            set: { newValue in
                /// Cleanup by removing any extra periods and non-numbers
                let newValue = newValue.sanitizedDouble
                customValueText = newValue
                
                /// If we haven't already set the flag for the trailing period, and the string has period as its last character, set it so that its displayed
                if !includeTrailingPeriod, newValue.last == "." {
                    includeTrailingPeriod = true
                }
                /// If we have set the flag for the trailing period and the last character isn't it—unset it
                else if includeTrailingPeriod, newValue.last != "." {
                    includeTrailingPeriod = false
                }
                
                if newValue == ".0" {
                    includeTrailingZero = true
                } else {
                    includeTrailingZero = false
                }
                
                let double = Double(newValue)
                customValueTextAsDouble = double
                
//                customValueText = if let customValueTextAsDouble {
//                    "\(customValueTextAsDouble)"
//                } else {
//                    ""
//                }
            }
        )
    }
}
