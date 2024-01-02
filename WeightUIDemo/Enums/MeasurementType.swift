import Foundation

enum MeasurementType {
    case weight
    case leanBodyMass
    case height
    case fatPercentage
    case energy
    
    var name: String {
        switch self {
        case .weight:           "Weight"
        case .leanBodyMass:     "Lean Body Mass"
        case .height:           "Height"
        case .fatPercentage:    "Fat Percentage"
            
        case .energy:           "Energy"
        }
    }
}
