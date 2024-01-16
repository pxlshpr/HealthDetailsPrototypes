import Foundation
import PrepShared

extension HealthDetails {
    struct LeanBodyMass: Hashable, Codable {
        var leanBodyMassInKg: Double? = nil
        var fatPercentage: Double? = nil
        var measurements: [LeanBodyMassMeasurement] = []
        var deletedHealthKitMeasurements: [LeanBodyMassMeasurement] = []
    }
}

extension HealthDetails.LeanBodyMass {
    func secondaryValueString() -> String? {
        if let fatPercentage {
            "\(fatPercentage.cleanHealth)%"
        } else {
            nil
        }
    }
    func valueString(in unit: BodyMassUnit) -> String {
        leanBodyMassInKg.valueString(convertedFrom: .kg, to: unit)
    }
}

extension HealthDetails {
    struct FatPercentage: Hashable, Codable {
        var fatPercentage: Double? = nil
    }
}

extension HealthDetails.FatPercentage {
    var valueString: String {
        guard let fatPercentage else { return NotSetString }
        return "\(fatPercentage.cleanHealth) %"
    }
}
