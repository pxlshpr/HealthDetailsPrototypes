import Foundation
import HealthKit

struct LeanBodyMassMeasurement: Hashable, Identifiable, Codable {
    let id: UUID
    let source: LeanBodyMassSource
    let date: Date
    let leanBodyMassInKg: Double
    let fatPercentage: Double? /// e.g. 10 for 10%

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
    
    init(sample: HKQuantitySample) {
        self.id = UUID()
        self.source = .healthKit(sample.uuid)
        self.date = sample.date
        self.leanBodyMassInKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
        self.fatPercentage = nil
    }
}
