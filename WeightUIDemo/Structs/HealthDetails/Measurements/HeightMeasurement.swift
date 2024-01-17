import Foundation
import HealthKit

struct HeightMeasurement: Hashable, Identifiable, Codable {
    let id: UUID
    let healthKitUUID: UUID?
    let date: Date
    let heightInCm: Double
    
    init(
        id: UUID = UUID(),
        date: Date,
        heightInCm: Double,
        healthKitUUID: UUID? = nil
    ) {
        self.init(id: id, date: date, value: heightInCm, healthKitUUID: healthKitUUID)
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
        self.heightInCm = value
    }    
}

