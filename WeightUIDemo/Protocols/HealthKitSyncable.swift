import Foundation
import HealthKit

protocol HealthKitSyncable {
    associatedtype MeasurementType: Measurable
    
    var value: Double? { get set }
    var measurements: [MeasurementType] { get set }
    var deletedHealthKitMeasurements: [MeasurementType] { get set }
    mutating func removeHealthKitQuantitySamples(notPresentIn samples: [HKQuantitySample])
    mutating func addNewHealthKitQuantitySamples(from samples: [HKQuantitySample], settingAsDeleted previouslyDeletedUUIDs: [UUID])
    
    var healthDetail: HealthDetail { get }
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
    
    mutating func addNewHealthKitQuantitySamples(
        from samples: [HKQuantitySample],
        settingAsDeleted previouslyDeletedUUIDs: [UUID]
    ) {

        func shouldAdd(_ sample: HKQuantitySample) -> Bool {
            !measurements.contains(where: { $0.healthKitUUID == sample.uuid })
            && !deletedHealthKitMeasurements.contains(where: { $0.healthKitUUID == sample.uuid })
        }
        
        for sample in samples {
            guard shouldAdd(sample) else { continue }
            
            let measurement = MeasurementType(healthKitQuantitySample: sample)
            if previouslyDeletedUUIDs.contains(sample.uuid) {
                deletedHealthKitMeasurements.append(measurement)
            } else {
                measurements.append(measurement)
            }
        }
        measurements.sort()
        deletedHealthKitMeasurements.sort()
        
//        let toAdd = samples.filter(shouldAdd)
//            .map { MeasurementType(healthKitQuantitySample: $0) }
//
//        measurements.append(contentsOf: toAdd)
//        measurements.sort()
    }
    
    mutating func setDailyMeasurement(for dailyMeasurementType: DailyMeasurementType) {
        self.value = measurements.dailyMeasurement(for: dailyMeasurementType)
    }
}


//MARK: - Conformances

extension HealthDetails.Weight: HealthKitSyncable {
    typealias MeasurementType = WeightMeasurement
    var healthDetail: HealthDetail { .weight }
    var value: Double? {
        get { weightInKg }
        set { weightInKg = newValue }
    }
}

extension HealthDetails.LeanBodyMass: HealthKitSyncable {
    typealias MeasurementType = LeanBodyMassMeasurement
    var healthDetail: HealthDetail { .leanBodyMass }
    var value: Double? {
        get { leanBodyMassInKg }
        set { leanBodyMassInKg = newValue }
    }
}

extension HealthDetails.FatPercentage: HealthKitSyncable {
    typealias MeasurementType = FatPercentageMeasurement
    var healthDetail: HealthDetail { .fatPercentage }
    var value: Double? {
        get { fatPercentage }
        set { fatPercentage = newValue }
    }
}

extension HealthDetails.Height: HealthKitSyncable {
    typealias MeasurementType = HeightMeasurement
    var healthDetail: HealthDetail { .height }
    var value: Double? {
        get { heightInCm }
        set { heightInCm = newValue }
    }
}

extension HealthKitSyncable {
    mutating func processHealthKitSamples(
        _ samples: [HKQuantitySample],
        for date: Date,
        toDelete: inout [HKQuantitySample],
        toExport: inout [any Measurable],
        settings: Settings
    ) {
        
        let filtered = samples
            .filter { $0.date.startOfDay == date.startOfDay }
            .removingSamplesWithTheSameValueAtTheSameTime(with: MeasurementType.healthKitUnit)

        let deletedUUIDs = deletedHealthKitMeasurements.compactMap { $0.healthKitUUID }
        
        removeHealthKitQuantitySamples(notPresentIn: filtered.notOurs)
        addNewHealthKitQuantitySamples(
            from: filtered.notOurs,
            settingAsDeleted: deletedUUIDs
        )
        toDelete.append(contentsOf: filtered.ours.notPresent(in: measurements))
        toExport.append(contentsOf: measurements.nonHealthKitMeasurements.notPresent(in: filtered.ours))
        setDailyMeasurement(for: settings.dailyMeasurementType(for: self.healthDetail))
    }
}
