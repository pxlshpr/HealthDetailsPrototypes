import HealthKit

enum HealthKitType {
    case weight
    case leanBodyMass
    case height
    case restingEnergy
    case activeEnergy
    case fatPercentage
    case dietaryEnergy
}

extension HealthKitType {
    
    static var syncedTypes: [HealthKitType] {
        [.weight, .leanBodyMass, .fatPercentage, .height]
    }

    static var fetchedTypes: [HealthKitType] {
        [.restingEnergy, .activeEnergy, .dietaryEnergy]
    }

    var healthKitTypeIdentifier: HKQuantityTypeIdentifier {
        switch self {
        case .weight:           .bodyMass
        case .leanBodyMass:     .leanBodyMass
        case .height:           .height
        case .restingEnergy:    .basalEnergyBurned
        case .activeEnergy:     .activeEnergyBurned
        case .fatPercentage:    .bodyFatPercentage
        case .dietaryEnergy:    .dietaryEnergyConsumed
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

extension HealthKitType {
    var defaultUnit: HKUnit {
        switch self {
        case .weight:           .gramUnit(with: .kilo)
        case .leanBodyMass:     .gramUnit(with: .kilo)
        case .height:           .meterUnit(with: .centi)
        case .restingEnergy:    .kilocalorie()
        case .activeEnergy:     .kilocalorie()
        case .fatPercentage:    .percent()
        case .dietaryEnergy:    .kilocalorie()
        }
    }
}
