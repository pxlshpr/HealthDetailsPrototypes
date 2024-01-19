import Foundation
import HealthKit

struct LeanBodyMassMeasurement: Hashable, Identifiable, Codable {
    let id: UUID
    let source: MeasurementSource
    let healthKitUUID: UUID?
    let equation: LeanBodyMassAndFatPercentageEquation?
    let date: Date
    var leanBodyMassInKg: Double
    let isConvertedFromFatPercentage: Bool

    init(
        id: UUID,
        date: Date,
        value: Double,
        healthKitUUID: UUID?
    ) {
        self.id = id
        self.source = if healthKitUUID != nil {
            .healthKit
        } else {
            .manual
        }
        self.healthKitUUID = healthKitUUID
        self.equation = nil
        self.date = date
        self.leanBodyMassInKg = value
        self.isConvertedFromFatPercentage = false
    }
    
    init(
        id: UUID = UUID(),
        date: Date,
        leanBodyMassInKg: Double,
        source: MeasurementSource,
        healthKitUUID: UUID?,
        equation: LeanBodyMassAndFatPercentageEquation? = nil,
        isConvertedFromFatPercentage: Bool = false
    ) {
        self.id = id
        self.source = source
        self.healthKitUUID = healthKitUUID
        self.date = date
        self.equation = equation
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
