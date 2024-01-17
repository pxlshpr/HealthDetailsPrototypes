import Foundation
import PrepShared
import HealthKit

extension HealthDetails {
    struct LeanBodyMass: Hashable, Codable {
        var leanBodyMassInKg: Double? = nil
        var measurements: [LeanBodyMassMeasurement] = []
        var deletedHealthKitMeasurements: [LeanBodyMassMeasurement] = []
    }
}

extension HealthDetails.LeanBodyMass {
    mutating func addHealthKitSample(_ sample: HKQuantitySample, using dailyValueType: DailyValueType) {
        guard !measurements.contains(where: { $0.healthKitUUID == sample.uuid }),
              !deletedHealthKitMeasurements.contains(where: { $0.healthKitUUID == sample.uuid })
        else {
            return
        }
        measurements.append(LeanBodyMassMeasurement(healthKitQuantitySample: sample))
        measurements.sort()
        leanBodyMassInKg = measurements.dailyValue(for: dailyValueType)
    }
    
    func valueString(in unit: BodyMassUnit) -> String {
        leanBodyMassInKg.valueString(convertedFrom: .kg, to: unit)
    }
}
