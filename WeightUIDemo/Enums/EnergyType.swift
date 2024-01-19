import HealthKit
import PrepShared

enum EnergyType {
    case resting
    case active
    case dietary

    var hkQuantityTypeIdentifier: HKQuantityTypeIdentifier {
        switch self {
        case .resting:  .basalEnergyBurned
        case .active:   .activeEnergyBurned
        case .dietary:  .dietaryEnergyConsumed
        }
    }
}
