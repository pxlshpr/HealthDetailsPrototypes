import Foundation

enum CorrectionType: Int, Codable, CaseIterable {
    case add = 1
    case subtract
    case multiply
    case divide
    
    var name: String {
        switch self {
        case .add:      "Add"
        case .subtract: "Subtract"
        case .multiply: "Multiply"
        case .divide:   "Divide"
        }
    }
    
    var label: String {
        switch self {
        case .add:      "Add"
        case .subtract: "Subtract"
        case .multiply: "Multiply by"
        case .divide:   "Divide by"
        }
    }
    
    var symbol: String {
        switch self {
        case .add:      "+"
        case .subtract: "-"
        case .multiply: "×"
        case .divide:   "÷"
        }
    }
    
    var textFieldPlaceholder: String {
        switch self {
        case .add:      "kcal to add"
        case .subtract: "kcal to subtract"
        case .multiply: "Multiply by"
        case .divide:   "Divide by"
        }
    }
    
    var unit: String? {
        switch self {
        case .add:      "kcal"
        case .subtract: "kcal"
        case .multiply: nil
        case .divide:   nil
        }
    }
}
