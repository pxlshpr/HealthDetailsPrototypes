import HealthKit
import PrepShared

enum EnergyType {
    case resting
    case active
    case dietary

    var healthKitType: HKQuantityType {
        HKQuantityType(healthKitTypeIdentifier)
    }
    
    var healthKitTypeIdentifier: HKQuantityTypeIdentifier {
        switch self {
        case .resting:  .basalEnergyBurned
        case .active:   .activeEnergyBurned
        case .dietary:  .dietaryEnergyConsumed
        }
    }
}
