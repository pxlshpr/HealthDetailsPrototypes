import Foundation
import PrepShared
import HealthKit

extension HealthDetails {
    struct FatPercentage: Hashable, Codable {
        var fatPercentage: Double? = nil
        var measurements: [FatPercentageMeasurement] = []
        var deletedHealthKitMeasurements: [FatPercentageMeasurement] = []
    }
}

extension HealthDetails.FatPercentage {
    mutating func addHealthKitSample(_ sample: HKQuantitySample, using dailyMeasurementType: DailyMeasurementType) {
        guard !measurements.contains(where: { $0.healthKitUUID == sample.uuid }),
              !deletedHealthKitMeasurements.contains(where: { $0.healthKitUUID == sample.uuid })
        else {
            return
        }
        measurements.append(FatPercentageMeasurement(healthKitQuantitySample: sample))
        measurements.sort()
        fatPercentage = measurements.dailyMeasurement(for: dailyMeasurementType)
    }

    var valueString: String {
        guard let fatPercentage else { return NotSetString }
        return "\(fatPercentage.cleanHealth) %"
    }
}
