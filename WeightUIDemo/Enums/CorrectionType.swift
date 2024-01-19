import Foundation

//enum CorrectionValue: Codable, Hashable {
//    case add(kcal: Double)
//    case subtract(kcal: Double)
//    case multiply(multiplier: Double)
//    case divide(divisor: Double)
//    
//    init?(type: CorrectionType, double: Double?) {
//        guard let double else {
//            return nil
//        }
//        switch type {
//        case .add:      self = .add(kcal: double)
//        case .subtract: self = .subtract(kcal: double)
//        case .multiply: self = .multiply(multiplier: double)
//        case .divide:   self = .divide(divisor: double)
//        }
//    }
//    
//    var type: CorrectionType {
//        switch self {
//        case .add: .add
//        case .subtract: .subtract
//        case .multiply: .multiply
//        case .divide: .divide
//        }
//    }
//    
//    var double: Double {
//        switch self {
//        case .add(let kcal):            kcal
//        case .subtract(let kcal):       kcal
//        case .multiply(let multiplier): multiplier
//        case .divide(let divisor):      divisor
//        }
//    }
//}

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
