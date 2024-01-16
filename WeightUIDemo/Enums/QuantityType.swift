import HealthKit

enum QuantityType {
    case weight
    case leanBodyMass
    case height
    case restingEnergy
    case activeEnergy
    case fatPercentage
}

extension QuantityType {
    
    var healthKitTypeIdentifier: HKQuantityTypeIdentifier {
        switch self {
        case .weight:           .bodyMass
        case .leanBodyMass:     .leanBodyMass
        case .height:           .height
        case .restingEnergy:    .basalEnergyBurned
        case .activeEnergy:     .activeEnergyBurned
        case .fatPercentage:    .bodyFatPercentage
        }
    }
    
    var healthDetail: HealthDetail? {
        switch self {
        case .weight:           .weight
        case .leanBodyMass:     .leanBodyMass
        case .height:           .height
        case .fatPercentage:    .fatPercentage
        default:                nil
        }
    }
}

extension QuantityType {
    var defaultUnit: HKUnit {
        switch self {
        case .weight:           .gramUnit(with: .kilo)
        case .leanBodyMass:     .gramUnit(with: .kilo)
        case .height:           .meterUnit(with: .centi)
        case .restingEnergy:    .kilocalorie()
        case .activeEnergy:     .kilocalorie()
        case .fatPercentage:    .percent()
        }
    }
}
