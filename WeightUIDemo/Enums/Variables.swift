import Foundation

enum Variables {
    case required([HealthDetail], String)
    
    /// Will ask for either Lean Body Mass or Fat Percentage and Weight (to calculate it)
    case leanBodyMass(String)
    
    var temporal: [HealthDetail] {
        switch self {
        case .required(let array, _):   array.temporalHealthDetails
        case .leanBodyMass:             [.leanBodyMass, .fatPercentage, .weight]
        }
    }
    
    var nonTemporal: [HealthDetail] {
        switch self {
        case .required(let array, _):   array.nonTemporalHealthDetails
        case .leanBodyMass:             []
        }
    }
    var description: String {
        switch self {
        case .required(_, let string):  string
        case .leanBodyMass(let string): string
        }
    }
    
    var isLeanBodyMass: Bool {
        switch self {
        case .leanBodyMass: true
        default:            false
        }
    }
}
