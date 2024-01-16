import HealthKit
import PrepShared

extension HealthStore {

    static func deleteMeasurements(_ toDelete: [HKQuantitySample]) async {
        do {
            try await self.store.delete(toDelete)
        } catch {
            fatalError("Error deleting measurements: \(error.localizedDescription)")
        }
    }
    static func saveMeasurements(_ measurements: [any Measurable]) async {
        do {
            let objects = measurements.map { measurement in
                HKQuantitySample(
                    type: HKQuantityType(.bodyMass),
                    quantity: HKQuantity(
                        unit: measurement.unit,
                        doubleValue: measurement.value
                    ),
                    start: measurement.date,
                    end: measurement.date,
                    metadata: [
                        HealthKitMetadataIDKey: measurement.id.uuidString
                    ]
                )
            }
            
            try await self.store.save(objects)
        } catch {
            fatalError("Error saving measurements: \(error.localizedDescription)")
        }
    }
}