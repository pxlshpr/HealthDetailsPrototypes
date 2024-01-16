import Foundation

enum LeanBodyMassAndFatPercentageSource: Codable, Hashable {
    case healthKit(UUID)
    case equation
    case converted
    case userEntered
    
    static var formCases: [LeanBodyMassAndFatPercentageSource] {
        [ .userEntered, .equation]
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
        case .converted:        "Converted"
        case .userEntered:      "Manual"
        }
    }
    
    var imageScale: Double {
        switch self {
        case .equation:
            0.8
        default:
            1.0
        }
    }
    
    var image: String {
        switch self {
        case .healthKit, .converted:
            ""
        case .equation:
            "function"
        case .userEntered:
            "pencil"
        }
    }
}
