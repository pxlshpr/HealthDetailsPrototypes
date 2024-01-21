import Foundation
import HealthKit
import PrepShared

extension HealthDetails {
    struct Height: Hashable, Codable {
        var heightInCm: Double? = nil
        var measurements: [HeightMeasurement] = []
        var deletedHealthKitMeasurements: [HeightMeasurement] = []
    }
}

extension HealthDetails.Height {
    
    mutating func addHealthKitSample(_ sample: HKQuantitySample, using dailyMeasurementType: DailyMeasurementType) {
        guard !measurements.contains(where: { $0.healthKitUUID == sample.uuid }),
              !deletedHealthKitMeasurements.contains(where: { $0.healthKitUUID == sample.uuid })
        else {
            return
        }
        measurements.append(HeightMeasurement(healthKitQuantitySample: sample))
        measurements.sort()
        heightInCm = measurements.dailyMeasurement(for: dailyMeasurementType)
    }
    
    func valueString(in unit: HeightUnit) -> String {
        heightInCm.valueString(convertedFrom: .cm, to: unit)
    }
}
