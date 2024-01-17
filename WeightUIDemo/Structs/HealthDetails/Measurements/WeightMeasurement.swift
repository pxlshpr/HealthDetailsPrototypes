import Foundation
import HealthKit

struct WeightMeasurement: Hashable, Identifiable, Codable {
    let id: UUID
    let healthKitUUID: UUID?
    let date: Date
    let weightInKg: Double

    init(
        id: UUID = UUID(),
        date: Date,
        weightInKg: Double,
        healthKitUUID: UUID? = nil
    ) {
        self.init(id: id, date: date, value: weightInKg, healthKitUUID: healthKitUUID)
    }

    init(
        id: UUID = UUID(),
        date: Date,
        value: Double,
        healthKitUUID: UUID? = nil
    ) {
        self.id = id
        self.healthKitUUID = healthKitUUID
        self.date = date
        self.weightInKg = value
    }
}
