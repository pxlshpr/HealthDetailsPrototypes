import Foundation

public struct Quantity: Hashable, Codable {
    public var value: Double
    public var date: Date?
    
    public init(value: Double, date: Date? = nil) {
        self.value = value
        self.date = date
    }
    
    init?(value: Double?)  {
        guard let value else {
            return nil
        }
        self.value = value
        self.date = nil
    }
}

extension Array where Element == HealthDetails.Weight {
    var averageValue: Double? {
        compactMap{ $0.weightInKg }.average
    }
}

extension Array where Element == Quantity {
    var valuesGroupedByDate: [Date: [Quantity]] {
        let withDates = self.filter { $0.date != nil }
        return Dictionary(grouping: withDates) { $0.date!.startOfDay }
    }
    
    var sortedByDate: [Quantity] {
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
    func asQuantity(in healthKitUnit: HKUnit) -> Quantity {
        let quantity = quantity.doubleValue(for: healthKitUnit)
        let date = startDate
        return Quantity(value: quantity, date: date)
    }
}

public extension Array where Element == Quantity {
    func removingDuplicateQuantities() -> [Quantity] {
        var addedDict = [Quantity: Bool]()
        
        return filter {
            let rounded = $0.rounded(toPlaces: 2)
            return addedDict.updateValue(true, forKey: rounded) == nil
        }
    }
}

extension Quantity {
    func rounded(toPlaces places: Int) -> Quantity {
        Quantity(
            value: self.value.rounded(toPlaces: places),
            date: self.date
        )
    }
}
