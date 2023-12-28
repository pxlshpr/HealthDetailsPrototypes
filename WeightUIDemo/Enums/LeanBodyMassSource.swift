import Foundation

enum LeanBodyMassSource: Int, Identifiable, Codable, CaseIterable {
    case healthKit = 1
    case equation
    case fatPercentage
    case userEntered
    
    static var formCases: [LeanBodyMassSource] {
        [.fatPercentage, .equation, .userEntered]
    }
    
    var name: String {
        switch self {
        case .healthKit:        "Apple Health"
        case .equation:         "Equation"
        case .fatPercentage:    "Fat %"
        case .userEntered:      "Custom"
        }
    }
    
    var id: Int {
        rawValue
    }
    
    var scale: Double {
        switch self {
        case .equation, .fatPercentage:
            0.8
        default:
            1.0
        }
    }
    
    var image: String {
        switch self {
        case .healthKit:
            ""
        case .equation:
            "function"
        case .fatPercentage:
            "percent"
        case .userEntered:
            "pencil"
        }
    }
}

