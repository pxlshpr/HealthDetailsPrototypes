import Foundation

protocol Measurable: Identifiable {
    var id: UUID { get }
    var healthKitUUID: UUID? { get }
    var date: Date { get }
    var value: Double { get }
    
    /// Optionals
    var secondaryValue: Double? { get }
    var secondaryValueUnit: String? { get }
    var imageType: MeasurementImageType { get }
    
    init(healthKitMeasurement: HealthKitMeasurement)
    init(id: UUID, date: Date, value: Double, healthKitUUID: UUID?)
}

extension Measurable {
    
    init(healthKitMeasurement: HealthKitMeasurement) {
        self.init(
            id: UUID(),
            date: healthKitMeasurement.date,
            value: healthKitMeasurement.value,
            healthKitUUID: healthKitMeasurement.id
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

extension Array where Element: Measurable {
    mutating func sort() {
        sort(by: { $0.date < $1.date })
    }
    
    func sorted() -> [Element] {
        return sorted(by: { $0.date < $1.date })
    }
}

extension Array where Element: Measurable {
    var nonHealthKitMeasurements: [Element] {
        filter { $0.healthKitUUID == nil }
    }
    
    func notPresent(in healthKitMeasurements: [HealthKitMeasurement]) -> [Element] {
        filter { measurement in
            !healthKitMeasurements.contains(where: { $0.prepID == measurement.id.uuidString })
        }
    }
}
