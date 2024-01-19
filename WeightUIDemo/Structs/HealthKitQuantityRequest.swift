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

    func allSamples(startingFrom startDate: Date?) async throws -> [HKQuantitySample]? {
        let predicate: NSPredicate? = if let startDate {
            NSPredicate(format: "startDate >= %@", startDate.startOfDay as NSDate)
        } else {
            nil
        }
        return try await samples(
            predicate: predicate,
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
    }
    
    func mostRecentSample(excluding uuidsToExclude: [UUID]) async throws -> HKQuantitySample? {
        let predicate = NSPredicate(format: "uuid NOT IN %@", uuidsToExclude.map({$0 as CVarArg}))
        return try await samples(
            predicate: predicate,
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 1
        ).first
    }
}

extension HealthKitQuantityRequest {
    
    var typeIdentifier: HKQuantityTypeIdentifier { quantityType.healthKitTypeIdentifier }

    func samples(
        predicate: NSPredicate? = nil,
        sortDescriptors: [SortDescriptor<HKQuantitySample>] = [],
        limit: Int? = nil
    ) async throws -> [HKQuantitySample] {
        let type = HKSampleType.quantityType(forIdentifier: typeIdentifier)!
        let samplePredicates = [HKSamplePredicate.quantitySample(type: type, predicate: predicate)]
        
        let asyncQuery = HKSampleQueryDescriptor(
            predicates: samplePredicates,
            sortDescriptors: sortDescriptors,
            limit: limit
        )

        return try await asyncQuery.result(for: HealthStore.store)
    }
}

extension Optional where Wrapped == [HKQuantitySample] {
    var isEmptyOrNil: Bool {
        self == nil || self?.isEmpty == true
    }
}

extension Date {
    var earliestDateForDietaryEnergyPoints: Date {
        moveDayBy(-(HealthInterval(MaxAdaptiveWeeks, .week).numberOfDays))
    }
}
