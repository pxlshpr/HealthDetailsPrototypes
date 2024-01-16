import Foundation
import PrepShared
import HealthKit

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
    mutating func addHealthKitSample(_ sample: HKQuantitySample, using dailyValueType: DailyValueType) {
        guard !measurements.contains(where: { $0.healthKitUUID == sample.uuid }),
              !deletedHealthKitMeasurements.contains(where: { $0.healthKitUUID == sample.uuid })
        else {
            return
        }
        measurements.append(WeightMeasurement(sample: sample))
        measurements.sort()
        weightInKg = measurements.dailyValue(for: dailyValueType)
    }

    func valueString(in unit: BodyMassUnit) -> String {
        weightInKg.valueString(convertedFrom: .kg, to: unit)
    }
}

