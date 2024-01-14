import Foundation
import HealthKit

protocol HealthKitSyncable {
    associatedtype MeasurementType: Measurable
    var measurements: [MeasurementType] { get set }
    var deletedHealthKitMeasurements: [MeasurementType] { get set }
    mutating func removeHealthKitQuantitySamples(notPresentIn samples: [HKQuantitySample])
    mutating func addNewHealthKitQuantitySamples(from samples: [HKQuantitySample])
}

//MARK: - Default implementations

extension HealthKitSyncable {
    
    mutating func removeHealthKitQuantitySamples(notPresentIn samples: [HKQuantitySample]) {
        
        func shouldRemove(_ measurement: MeasurementType) -> Bool {
            guard let id = measurement.healthKitUUID else { return false }
            return !samples.contains(where: { $0.uuid == id })
        }
        
        measurements.removeAll(where: shouldRemove)
        deletedHealthKitMeasurements.removeAll(where: shouldRemove)
    }
    
    mutating func addNewHealthKitQuantitySamples(from samples: [HKQuantitySample]) {

        func shouldAdd(_ sample: HKQuantitySample) -> Bool {
            !measurements.contains(where: { $0.healthKitUUID == sample.uuid })
            && !deletedHealthKitMeasurements.contains(where: { $0.healthKitUUID == sample.uuid })
        }
        
        let toAdd = samples.filter(shouldAdd)
            .map { MeasurementType(healthKitQuantitySample: $0) }

        measurements.append(contentsOf: toAdd)
        measurements.sort()
    }
}

//MARK: - Conformances

extension HealthDetails.Weight: HealthKitSyncable {
    typealias MeasurementType = WeightMeasurement
}

extension HealthDetails.LeanBodyMass: HealthKitSyncable {
    typealias MeasurementType = LeanBodyMassMeasurement
}

extension HealthDetails.Height: HealthKitSyncable {
    typealias MeasurementType = HeightMeasurement
}
