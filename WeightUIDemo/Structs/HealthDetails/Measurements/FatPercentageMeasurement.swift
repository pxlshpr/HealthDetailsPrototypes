import Foundation

struct FatPercentageMeasurement: Hashable, Identifiable, Codable {
    let id: UUID
    let source: LeanBodyMassSource
    let date: Date
    let fatPercentage: Double?
    let leanBodyMassInKg: Double

    init(
        id: UUID,
        date: Date,
        value: Double,
        healthKitUUID: UUID?
    ) {
        self.id = id
        self.source = if let healthKitUUID {
            .healthKit(healthKitUUID)
        } else {
            .userEntered
        }
        self.date = date
        self.leanBodyMassInKg = value
        self.fatPercentage = nil
    }
    
    init(
        id: UUID = UUID(),
        date: Date,
        leanBodyMassInKg: Double,
        fatPercentage: Double? = nil,
        source: LeanBodyMassSource
    ) {
        self.id = id
        self.source = source
        self.date = date
        self.leanBodyMassInKg = leanBodyMassInKg
        self.fatPercentage = fatPercentage
    }
}
