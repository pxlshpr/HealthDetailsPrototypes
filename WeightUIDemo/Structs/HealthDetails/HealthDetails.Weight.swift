import Foundation
import PrepShared

extension HealthDetails {
    struct Weight: Hashable, Codable {
        var weightInKg: Double? = nil
        var measurements: [WeightMeasurement] = []
        var deletedHealthKitMeasurements: [WeightMeasurement] = []
    }
}

extension Array where Element == HealthDetails.Weight {
    var averageValue: Double? {
        compactMap{ $0.weightInKg }.average
    }
}

extension HealthDetails.Weight {
    func valueString(in unit: BodyMassUnit) -> String {
        weightInKg.valueString(convertedFrom: .kg, to: unit)
    }
}

