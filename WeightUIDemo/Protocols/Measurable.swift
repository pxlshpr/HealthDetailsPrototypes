import Foundation
import HealthKit

protocol Measurable: Identifiable {
    var id: UUID { get }
    var healthKitUUID: UUID? { get }
    var date: Date { get }
    var value: Double { get }
    static var healthKitUnit: HKUnit { get }
    var unit: HKUnit { get }

    /// Optionals
    var secondaryValue: Double? { get }
    var secondaryValueUnit: String? { get }
    var imageType: MeasurementImageType { get }
    
    init(healthKitQuantitySample: HKQuantitySample)
    init(id: UUID, date: Date, value: Double, healthKitUUID: UUID?)
}

extension Measurable {
    
    init(healthKitQuantitySample sample: HKQuantitySample) {
        self.init(
            id: UUID(),
            date: sample.date,
            value: sample.quantity.doubleValue(for: Self.healthKitUnit),
            healthKitUUID: sample.uuid
        )
    }
    
    var secondaryValue: Double? {
        nil
    }
    
    var secondaryValueUnit: String? {
        nil
    }
    
    var imageType: MeasurementImageType {
        if isFromHealthKit {
            .healthKit
        } else {
            .systemImage("pencil")
        }
    }
}

extension Measurable {
    
    var secondaryValueString: String? {
        if let secondaryValue, let secondaryValueUnit {
            "\(secondaryValue.cleanHealth)\(secondaryValueUnit)"
        } else {
            nil
        }
    }
    
    var timeString: String {
        date.healthTimeString
    }
    
    var isFromHealthKit: Bool {
        healthKitUUID != nil
    }
}

//MARK: - Conformances

extension HeightMeasurement: Measurable {
    var value: Double { heightInCm }
    static var healthKitUnit: HKUnit { .meterUnit(with: .centi) }
    var unit: HKUnit { .meterUnit(with: .centi) }
}


extension WeightMeasurement: Measurable {
    var value: Double { weightInKg }
    static var healthKitUnit: HKUnit { .gramUnit(with: .kilo) }
    var unit: HKUnit { .gramUnit(with: .kilo) }
}

extension LeanBodyMassMeasurement: Measurable {
    var value: Double { leanBodyMassInKg }
    static var healthKitUnit: HKUnit { .gramUnit(with: .kilo) }
    var unit: HKUnit { .gramUnit(with: .kilo) }

    var healthKitUUID: UUID? { source.healthKitUUID }
    var secondaryValue: Double? { fatPercentage?.rounded(toPlaces: 1) }
    var secondaryValueUnit: String? { "%" }
    
    var imageType: MeasurementImageType {
        switch source {
        case .healthKit:    .healthKit
        default:            .systemImage(source.image, source.imageScale)
        }
    }
}



//MARK: - Array extensions

extension Array where Element: Measurable {
    mutating func sort() {
        sort(by: { $0.date < $1.date })
    }
    
    func sorted() -> [Element] {
        return sorted(by: { $0.date < $1.date })
    }
}

extension Array where Element: Measurable {
    func dailyValue(for dailyValueType: DailyValueType) -> Double? {
        switch dailyValueType {
        case .average:  compactMap { $0.value }.average
        case .last:     last?.value
        case .first:    first?.value
        }
    }

    var nonHealthKitMeasurements: [Element] {
        filter { $0.healthKitUUID == nil }
    }
    
    func notPresent(in samples: [HKQuantitySample]) -> [Element] {
        filter { measurement in
            !samples.contains(where: { $0.prepID == measurement.id.uuidString })
        }
    }
}
