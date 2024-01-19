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

let preview_healthKitUUID = UUID(uuidString: "52575A8B-8A42-4E9E-96F4-548261591D9A")!
let preview_healthKitLBMDate = Date(fromDateString: "2022_11_27")!

extension HealthDetails.LeanBodyMass {
    mutating func preview_addHealthKitSample(dailyValueType: DailyValueType)
    {
        let uuid = preview_healthKitUUID
        let date = preview_healthKitLBMDate
        
        guard !measurements.contains(where: { $0.healthKitUUID == uuid }),
              !deletedHealthKitMeasurements.contains(where: { $0.healthKitUUID == uuid })
        else {
            return
        }
        measurements.append(
            LeanBodyMassMeasurement(
                id: UUID(),
                date: date,
                value: 69.9,
                healthKitUUID: preview_healthKitUUID
            )
        )
        measurements.sort()
        leanBodyMassInKg = measurements.dailyValue(for: dailyValueType)
    }
}
