import HealthKit
import PrepShared

struct HealthKitQuantityRequest {
    let quantityType: QuantityType
    let healthKitUnit: HKUnit
//    let date: Date
    
    init(
        _ type: QuantityType,
        _ unit: HKUnit
//        _ date: Date
    ) {
        self.quantityType = type
        self.healthKitUnit = unit
//        self.date = date
    }
    
    static var weight: HealthKitQuantityRequest {
        self.init(.weight, .gramUnit(with: .kilo))
    }
    static var leanBodyMass: HealthKitQuantityRequest {
        self.init(.leanBodyMass, .gramUnit(with: .kilo))
    }
    static var height: HealthKitQuantityRequest {
        self.init(.height, .meterUnit(with: .centi))
    }
}

extension Array where Element == Date {
    var predicateForHealthKitQuantities: NSPredicate? {
        guard !isEmpty else { return nil }
        var subpredicates: [NSPredicate] = []
        for date in self {
            let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "startDate >= %@", date.startOfDay as NSDate),
                NSPredicate(format: "startDate <= %@", date.endOfDay as NSDate)
            ])
            subpredicates.append(predicate)
        }
        return NSCompoundPredicate(orPredicateWithSubpredicates: subpredicates)
    }
}

extension HealthKitQuantityRequest {

    func quantities(for dates: [Date]) async throws -> [Quantity] {
        guard let predicate = dates.predicateForHealthKitQuantities else { return [] }
        return try await quantities(matching: predicate)
    }
    
//    func daySample(movingAverageInterval interval: HealthInterval? = nil) async throws -> DaySample? {
//        nil
//
////        let days = interval?.numberOfDays ?? 0
////
////        //TODO: Write this properly
////        /// [ ] Get all quantities from start of earliest day to end of last day (provided date)
////        /// [ ] Now average out all the days and get an array of the daily values (should be `days` long)
////        /// [ ] Now average this value out so that we get the moving average value
////        /// [x] Now incorporate both this and weight(on:) in a single function that gets provided an `asMovingAverage` parameter
////        /// [x] Now test that this works
////        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
////            NSPredicate(format: "startDate >= %@", date.moveDayBy(-days).startOfDay as NSDate),
////            NSPredicate(format: "startDate <= %@", date.endOfDay as NSDate)
////        ])
////
////        let quantities = try await quantities(matching: predicate)
////        let groupedByDate = quantities.valuesGroupedByDate
////
////        var movingAverageValues: [Int: Double] = [:]
////        for (quantitiesDate, quantities) in groupedByDate {
////            let numberOfDays = date.numberOfDaysFrom(quantitiesDate)
////            guard numberOfDays >= 0 else { continue }
////
////            let dailyAverage = quantities.map { $0.value }.averageValue
////            guard let dailyAverage else { continue }
////
////            movingAverageValues[numberOfDays] = dailyAverage
////        }
////
////        guard let average = Array(movingAverageValues.values).averageValue else { return nil }
////
////        return DaySample(
////            value: average,
////            movingAverageValues: movingAverageValues.isEmpty ? nil : movingAverageValues
////        )
//    }
}

extension HealthKitQuantityRequest {

    func mostRecentOrEarliestAvailable(to date: Date) async throws -> Quantity? {
//        var date = date
//        if date.isToday {
//            date = date.startOfDay
//        } else {
//            date = date.endOfDay
//        }
        guard let mostRecent = try await mostRecent(to: date.endOfDay) else {
            return try await earliestAvailable()
        }
        return mostRecent
    }

    func mostRecentDaysQuantities(to date: Date) async throws -> [Quantity]? {
        guard let latestDate = try await mostRecentOrEarliestAvailable(to: date)?.date else {
            return nil
        }
        return try await daysQuantities(for: latestDate)
    }

    func daysQuantities(for range: ClosedRange<Date>) async throws -> [Quantity]? {
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "startDate >= %@", range.lowerBound.startOfDay as NSDate),
            NSPredicate(format: "startDate <= %@", range.upperBound.endOfDay as NSDate),
        ])
        return try await samples(
            matching: predicate,
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
        .map { $0.asQuantity(in: healthKitUnit) }
    }
    
    func daysQuantities(for date: Date) async throws -> [Quantity]? {
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "startDate >= %@", date.startOfDay as NSDate),
            NSPredicate(format: "startDate <= %@", date.endOfDay as NSDate),
        ])
        return try await samples(
            matching: predicate,
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
        .map { $0.asQuantity(in: healthKitUnit) }
    }

    func allQuantities() async throws -> [Quantity]? {
        return try await samples(
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
        .map { $0.asQuantity(in: healthKitUnit) }
    }

    func mostRecent(to date: Date) async throws -> Quantity? {
        try await firstQuantity(
            matching: NSPredicate(format: "startDate <= %@", date as NSDate),
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]
        )
    }
    
    func earliestAvailable() async throws -> Quantity? {
        try await firstQuantity(
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
    }
}

extension HealthKitQuantityRequest {
    
    var typeIdentifier: HKQuantityTypeIdentifier { quantityType.healthKitTypeIdentifier }

    func requestPersmissions() async throws {
        try await HealthStore.requestPermissions(quantityTypeIdentifiers: [typeIdentifier])
    }

    func samples(
        matching predicate: NSPredicate? = nil,
        sortDescriptors: [SortDescriptor<HKQuantitySample>] = [],
        limit: Int? = nil
    ) async throws -> [HKQuantitySample] {
        try await requestPersmissions()

        let type = HKSampleType.quantityType(forIdentifier: typeIdentifier)!
        let samplePredicates = [HKSamplePredicate.quantitySample(type: type, predicate: predicate)]
        
        let asyncQuery = HKSampleQueryDescriptor(
            predicates: samplePredicates,
            sortDescriptors: sortDescriptors,
            limit: limit
        )

        return try await asyncQuery.result(for: HealthStore.store)
    }
    
    func quantities(
        matching predicate: NSPredicate? = nil,
        sortDescriptors: [SortDescriptor<HKQuantitySample>] = []
    ) async throws -> [Quantity] {
        try await samples(matching: predicate, sortDescriptors: sortDescriptors)
            .map { $0.asQuantity(in: healthKitUnit) }
    }

    func firstQuantity(
        matching predicate: NSPredicate? = nil,
        sortDescriptors: [SortDescriptor<HKQuantitySample>] = []
    ) async throws -> Quantity? {
        try await samples(
            matching: predicate,
            sortDescriptors: sortDescriptors,
            limit: 1
        )
        .first?
        .asQuantity(in: healthKitUnit)
    }
}
