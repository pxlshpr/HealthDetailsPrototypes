import HealthKit

public enum CharacteristicType {
    case sex
    case dateOfBirth
}

public extension CharacteristicType {
    
    var healthType: HKCharacteristicTypeIdentifier {
        switch self {
        case .sex:          .biologicalSex
        case .dateOfBirth:  .dateOfBirth
        }
    }
}
