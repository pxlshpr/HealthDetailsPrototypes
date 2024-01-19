import Foundation

enum MeasurementSource: Int, Codable, Hashable {
    case healthKit = 1
    case equation
    case manual
    
    static var formCases: [MeasurementSource] {
        [ .manual, .equation]
    }
    
    var isFromHealthKit: Bool {
        switch self {
        case .healthKit:    true
        default:            false
        }
    }
    
    var name: String {
        switch self {
        case .healthKit:        "Apple Health"
        case .equation:         "Equation"
        case .manual:      "Manual"
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
        case .healthKit:
            ""
        case .equation:
            "function"
        case .manual:
            "pencil"
        }
    }
}

