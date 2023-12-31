import SwiftUI

/// Provides a binding for inputting a double
class IntInput {
    
    var int: Int?
    var stringAsInt: Int?
    var string: String

    let automaticallySubmitsValues: Bool

    init(int: Int? = nil, automaticallySubmitsValues: Bool = false) {
        self.int = int
        self.stringAsInt = int
        self.string = if let int {
            "\(int)"
        } else {
            ""
        }
        
        self.automaticallySubmitsValues = automaticallySubmitsValues
    }
    
    var binding: Binding<String> {
        Binding<String>(
            get: {
                return self.string
            },
            set: { newValue in
                self.setNewValue(newValue)
            }
        )
    }

    func setNewValue(_ int: Int?) {
        self.int = int
        stringAsInt = int
        string = if let int {
            "\(int)"
        } else {
            ""
        }
        if automaticallySubmitsValues {
            submitValue()
        }
    }
    
    func setNewValue(_ string: String) {
        let int = Int(string)
        setNewValue(int)
    }
    
    func submitValue() {
        int = stringAsInt
    }
    
    func cancel() {
        guard let int else {
            string = ""
            stringAsInt = nil
            return
        }
        string = "\(int)"
        stringAsInt = int
    }
}
