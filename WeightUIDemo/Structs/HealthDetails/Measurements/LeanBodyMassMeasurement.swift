import Foundation
import HealthKit

struct LeanBodyMassMeasurement: Hashable, Identifiable, Codable {
    let id: UUID
    let source: LeanBodyMassAndFatPercentageSource
    let date: Date
    let leanBodyMassInKg: Double
    let isConvertedFromFatPercentage: Bool

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
        self.isConvertedFromFatPercentage = false
    }
    
    init(
        id: UUID = UUID(),
        date: Date,
        leanBodyMassInKg: Double,
        source: LeanBodyMassAndFatPercentageSource,
        isConvertedFromFatPercentage: Bool = false
    ) {
        self.id = id
        self.source = source
        self.date = date
        self.leanBodyMassInKg = leanBodyMassInKg
        self.isConvertedFromFatPercentage = isConvertedFromFatPercentage
    }
}

extension Array where Element == LeanBodyMassMeasurement {
    var nonConverted: [LeanBodyMassMeasurement] {
        filter { !$0.isConvertedFromFatPercentage }
    }
    
    var converted: [LeanBodyMassMeasurement] {
        filter { $0.isConvertedFromFatPercentage }
    }
}
