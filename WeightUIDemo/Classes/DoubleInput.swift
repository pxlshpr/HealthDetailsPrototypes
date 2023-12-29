import SwiftUI

/// Provides a binding for inputting a double
class DoubleInput {
    
    var double: Double?
    var stringAsDouble: Double?
    var string: String

    var includeTrailingPeriod: Bool = false
    var includeTrailingZero: Bool = false
    var numberOfTrailingZeros: Int = 0

    init(double: Double? = nil) {
        self.double = double
        self.stringAsDouble = double
        self.string = double?.clean ?? ""
    }
    
    var binding: Binding<String> {
        Binding<String>(
            get: { self.string },
            set: { newValue in
                self.setNewValue(newValue)
            }
        )
    }
    
    func setNewValue(_ newValue: String) {
        /// Cleanup by removing any extra periods and non-numbers
        let newValue = newValue.sanitizedDouble
        string = newValue
        
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
        stringAsDouble = double
    }
    
    func submitValue() {
        double = stringAsDouble
    }
}
