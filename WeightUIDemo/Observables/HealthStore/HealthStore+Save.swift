import HealthKit
import PrepShared

extension HealthStore {

    static func deleteMeasurements(_ toDelete: [HKQuantitySample]) async {
        do {
            try await self.store.delete(toDelete)
        } catch {
            /// This can happen when objects already deleted are tried to be deleted again
//            fatalError("Error deleting measurements: \(error.localizedDescription)")
        }
    }
    static func saveMeasurements(_ measurements: [any Measurable]) async {
        do {
            let objects = measurements.map { measurement in
                HKQuantitySample(
                    type: measurement.hkQuantityType,
                    quantity: HKQuantity(
                        unit: measurement.unit,
                        doubleValue: measurement.valueToExport
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
