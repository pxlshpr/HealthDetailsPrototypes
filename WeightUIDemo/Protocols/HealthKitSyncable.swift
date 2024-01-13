import Foundation

protocol HealthKitSyncable {
    associatedtype MeasurementType: Measurable
    var measurements: [MeasurementType] { get set }
    var deletedHealthKitMeasurements: [MeasurementType] { get set }
    mutating func removeHealthKitMeasurements(notPresentIn healthKitMeasurements: [HealthKitMeasurement])
    mutating func addNewHealthKitMeasurements(from healthKitMeasurements: [HealthKitMeasurement])
}

//MARK: - Default implementations

extension HealthKitSyncable {
    
    mutating func removeHealthKitMeasurements(notPresentIn healthKitMeasurements: [HealthKitMeasurement]) {
        
        func shouldRemove(_ measurement: MeasurementType) -> Bool {
            guard let id = measurement.healthKitUUID else { return false }
            return !healthKitMeasurements.contains(where: { $0.id == id })
        }
        
        measurements.removeAll(where: shouldRemove)
        deletedHealthKitMeasurements.removeAll(where: shouldRemove)
    }
    
    mutating func addNewHealthKitMeasurements(from healthKitMeasurements: [HealthKitMeasurement]) {

        func shouldAdd(_ healthKitMeasurement: HealthKitMeasurement) -> Bool {
            !measurements.contains(where: { $0.id == healthKitMeasurement.id })
            && !deletedHealthKitMeasurements.contains(where: { $0.id == healthKitMeasurement.id })
        }
        
        let toAdd = healthKitMeasurements.filter(shouldAdd)
            .map { MeasurementType(healthKitMeasurement: $0) }
        measurements.append(contentsOf: toAdd)
        measurements.sort()
    }
}

//MARK: - Conformances

extension HealthDetails.Weight: HealthKitSyncable {
    typealias MeasurementType = WeightMeasurement
}

