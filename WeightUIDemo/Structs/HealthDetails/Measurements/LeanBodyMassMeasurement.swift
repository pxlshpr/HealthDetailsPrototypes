import Foundation
import HealthKit

struct LeanBodyMassMeasurement: Hashable, Identifiable, Codable {
    let id: UUID
    let source: LeanBodyMassAndFatPercentageSource
    let date: Date
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
    }
    
    init(
        id: UUID = UUID(),
        date: Date,
        leanBodyMassInKg: Double,
        source: LeanBodyMassAndFatPercentageSource
    ) {
        self.id = id
        self.source = source
        self.date = date
        self.leanBodyMassInKg = leanBodyMassInKg
    }
    
//    init(healthKitQuantitySample sample: HKQuantitySample) {
//        self.id = UUID()
//        self.source = .healthKit(sample.uuid)
//        self.date = sample.date
//        self.leanBodyMassInKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
//    }
}
