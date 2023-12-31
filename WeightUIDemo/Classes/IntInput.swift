import SwiftUI

/// Provides a binding for inputting a double
class IntInput {
    
    var int: Int?
    var stringAsInt: Int?
    var string: String

    init(int: Int? = nil) {
        self.int = int
        self.stringAsInt = int
        self.string = if let int {
            "\(int)"
        } else {
            ""
        }
    }
    
    var binding: Binding<String> {
        Binding<String>(
            get: {
                print("Returning: \(self.string)")
                return self.string
            },
            set: { newValue in
                print("Setting: \(newValue)")
                self.setNewValue(newValue)
            }
        )
    }

    func setNewValue(_ int: Int?) {
        self.int = int
        self.stringAsInt = int
        self.string = if let int {
            "\(int)"
        } else {
            ""
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
