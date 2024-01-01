import Foundation

enum LeanBodyMassSource: Codable, Hashable {
    case healthKit(UUID)
    case equation
    case fatPercentage
    case userEntered
    
    static var formCases: [LeanBodyMassSource] {
        [ .userEntered, .fatPercentage, .equation]
    }
    
    var isFromHealthKit: Bool {
        switch self {
        case .healthKit:    true
        default:            false
        }
    }
    
    var healthKitUUID: UUID? {
        switch self {
        case .healthKit(let uuid):  uuid
        default:                    nil
        }
    }
    
    var name: String {
        switch self {
        case .healthKit:        "Apple Health"
        case .equation:         "Equation"
        case .fatPercentage:    "Fat %"
        case .userEntered:      "Manual"
        }
    }
    
//    var id: Int {
//        self
//    }
    
    var imageScale: Double {
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

