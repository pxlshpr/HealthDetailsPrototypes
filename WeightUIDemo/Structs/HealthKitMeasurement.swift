import Foundation

public struct HealthKitMeasurement: Hashable, Codable {
    public var id: UUID
    public var value: Double
    public var date: Date?
    
    public init(id: UUID, value: Double, date: Date? = nil) {
        self.id = id
        self.value = value
        self.date = date
    }
    
//    init?(value: Double?)  {
//        guard let value else {
//            return nil
//        }
//        self.value = value
//        self.date = nil
//    }
}

extension Array where Element == HealthDetails.Weight {
    var averageValue: Double? {
        compactMap{ $0.weightInKg }.average
    }
}

extension Array where Element == HealthKitMeasurement {
    var valuesGroupedByDate: [Date: [HealthKitMeasurement]] {
        let withDates = self.filter { $0.date != nil }
        return Dictionary(grouping: withDates) { $0.date!.startOfDay }
    }
    
    var sortedByDate: [HealthKitMeasurement] {
        self.sorted(by: { lhs, rhs in
            switch (lhs.date, rhs.date) {
            case (.some(let date1), .some(let date2)):  date1 < date2
            case (.some, .none):                        true
            case (.none, .some):                        false
            case (.none, .none):                        false
            }
        })
    }
    
    var averageValue: Double? {
        map{ $0.value }.average
    }
}

import HealthKit

extension HKQuantitySample {
    func asHealthKitMeasurement(in healthKitUnit: HKUnit) -> HealthKitMeasurement {
        let quantity = quantity.doubleValue(for: healthKitUnit)
        let date = startDate
        return HealthKitMeasurement(
            id: uuid,
            value: quantity,
            date: date
        )
    }
}

public extension Array where Element == HealthKitMeasurement {
    func removingDuplicateQuantities() -> [HealthKitMeasurement] {
        var addedDict = [HealthKitMeasurement: Bool]()
        
        return filter {
            let rounded = $0.rounded(toPlaces: 2)
            return addedDict.updateValue(true, forKey: rounded) == nil
        }
    }
}

extension HealthKitMeasurement {
    func rounded(toPlaces places: Int) -> HealthKitMeasurement {
        HealthKitMeasurement(
            id: id,
            value: value.rounded(toPlaces: places),
            date: date
        )
    }
}
