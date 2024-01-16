import Foundation
import HealthKit

struct FatPercentageMeasurement: Hashable, Identifiable, Codable {
    let id: UUID
    let source: LeanBodyMassSource
    let date: Date
    let fatPercentage: Double
    let leanBodyMassInKg: Double?

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
        self.fatPercentage = value
        self.leanBodyMassInKg = nil
    }
    
    init(
        id: UUID = UUID(),
        date: Date,
        fatPercentage: Double,
        leanBodyMassInKg: Double? = nil,
        source: LeanBodyMassSource
    ) {
        self.id = id
        self.source = source
        self.date = date
        self.fatPercentage = fatPercentage
        self.leanBodyMassInKg = leanBodyMassInKg
    }
    
    init(sample: HKQuantitySample) {
        self.id = UUID()
        self.source = .healthKit(sample.uuid)
        self.date = sample.date
        self.fatPercentage = sample.quantity.doubleValue(for: .percent())
        self.leanBodyMassInKg = nil
    }
}
