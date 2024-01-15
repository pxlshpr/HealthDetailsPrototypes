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
    
    mutating func addHealthKitSample(_ sample: HKQuantitySample) {
        
        guard !measurements.contains(where: { $0.healthKitUUID == sample.uuid }),
              !deletedHealthKitMeasurements.contains(where: { $0.healthKitUUID == sample.uuid })
        else {
            return
        }
        measurements.append(HeightMeasurement(sample: sample))
        measurements.sort()
        heightInCm = measurements.last?.heightInCm
    }
    
    func valueString(in unit: HeightUnit) -> String {
        heightInCm.valueString(convertedFrom: .cm, to: unit)
    }
}
