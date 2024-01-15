import Foundation
import HealthKit

protocol HealthKitSyncable {
    associatedtype MeasurementType: Measurable
    
    var value: Double? { get set }
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
    
    mutating func setDailyValue(for dailyValueType: DailyValueType) {
        self.value = measurements.dailyValue(for: dailyValueType)
    }
}


//MARK: - Conformances

extension HealthDetails.Weight: HealthKitSyncable {
    typealias MeasurementType = WeightMeasurement
    var value: Double? {
        get { weightInKg }
        set { weightInKg = newValue }
    }
}

extension HealthDetails.LeanBodyMass: HealthKitSyncable {
    typealias MeasurementType = LeanBodyMassMeasurement
    var value: Double? {
        get { leanBodyMassInKg }
        set { leanBodyMassInKg = newValue }
    }
}

extension HealthDetails.Height: HealthKitSyncable {
    typealias MeasurementType = HeightMeasurement
    var value: Double? {
        get { heightInCm }
        set { heightInCm = newValue }
    }
}
