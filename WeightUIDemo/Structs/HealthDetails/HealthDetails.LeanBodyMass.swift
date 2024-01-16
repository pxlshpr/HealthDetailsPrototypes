import Foundation
import PrepShared
import HealthKit

extension HealthDetails {
    struct LeanBodyMass: Hashable, Codable {
        var leanBodyMassInKg: Double? = nil
//        var fatPercentage: Double? = nil
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
        measurements.append(LeanBodyMassMeasurement(sample: sample))
        measurements.sort()
        leanBodyMassInKg = measurements.dailyValue(for: dailyValueType)
    }
    
//    func secondaryValueString() -> String? {
//        if let fatPercentage {
//            "\(fatPercentage.cleanHealth)%"
//        } else {
//            nil
//        }
//    }
    func valueString(in unit: BodyMassUnit) -> String {
        leanBodyMassInKg.valueString(convertedFrom: .kg, to: unit)
    }
}

extension HealthDetails {
    struct FatPercentage: Hashable, Codable {
        var fatPercentage: Double? = nil
        var measurements: [FatPercentageMeasurement] = []
        var deletedHealthKitMeasurements: [FatPercentageMeasurement] = []
    }
}

extension HealthDetails.FatPercentage {
    mutating func addHealthKitSample(_ sample: HKQuantitySample, using dailyValueType: DailyValueType) {
        guard !measurements.contains(where: { $0.healthKitUUID == sample.uuid }),
              !deletedHealthKitMeasurements.contains(where: { $0.healthKitUUID == sample.uuid })
        else {
            return
        }
        measurements.append(FatPercentageMeasurement(sample: sample))
        measurements.sort()
        fatPercentage = measurements.dailyValue(for: dailyValueType)
    }

    var valueString: String {
        guard let fatPercentage else { return NotSetString }
        return "\(fatPercentage.cleanHealth) %"
    }
}
