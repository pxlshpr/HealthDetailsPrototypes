import Foundation
import HealthKit

struct FatPercentageMeasurement: Hashable, Identifiable, Codable {
    let id: UUID
    let source: LeanBodyMassAndFatPercentageSource
    let date: Date
    let percent: Double

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
        self.percent = value
    }
    
    init(
        id: UUID = UUID(),
        date: Date,
        percent: Double,
        source: LeanBodyMassAndFatPercentageSource
    ) {
        self.id = id
        self.source = source
        self.date = date
        self.percent = percent
    }
    
    init(sample: HKQuantitySample) {
        self.id = UUID()
        self.source = .healthKit(sample.uuid)
        self.date = sample.date
        self.percent = sample.quantity.doubleValue(for: .percent())
    }
}
