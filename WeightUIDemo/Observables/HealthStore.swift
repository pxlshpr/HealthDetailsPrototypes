import HealthKit
import PrepShared

public class HealthStore {
    
    internal static let shared = HealthStore()
    internal static let store: HKHealthStore = HKHealthStore()
    
    public static var defaultUnitHandler: ((QuantityType) -> HKUnit)? = nil
}

extension HealthStore {
    
    static func latestQuantity(for type: QuantityType, using unit: HKUnit? = nil) async -> Quantity? {
        do {
            try await requestPermission(for: type)
            return try await latestQuantity(
                for: type,
                using: unit ?? defaultUnitHandler?(type),
                excludingToday: false
            )
        } catch {
            return nil
        }
    }
    
    static func biologicalSex_legacy() async -> HKBiologicalSex? {
        do {
            try await requestPermission(for: .biologicalSex)
            return try store.biologicalSex().biologicalSex
        } catch {
            return nil
        }
    }
    
    static func dateOfBirthComponents_legacy() async -> DateComponents? {
        do {
            try await requestPermission(for: .dateOfBirth)
            return try store.dateOfBirthComponents()
        } catch {
            return nil
        }
    }
    
    static func requestPermissions(
        characteristicTypeIdentifiers: [CharacteristicType] = [],
        quantityTypes: [QuantityType] = []
    ) async throws {
        try await requestPermissions(
            characteristicTypeIdentifiers: characteristicTypeIdentifiers.map { $0.healthType },
            quantityTypeIdentifiers: quantityTypes.map { $0.healthKitTypeIdentifier })
    }
}

extension HealthStore {
    static func latestQuantity(for type: QuantityType, using heightUnit: HeightUnit? = nil) async -> Quantity? {
        await latestQuantity(for: type, using: heightUnit?.healthKitUnit)
    }
    
    static func latestQuantity(for type: QuantityType, using bodyMassUnit: BodyMassUnit? = nil) async -> Quantity? {
        await latestQuantity(for: type, using: bodyMassUnit?.healthKitUnit)
    }
}

extension HealthStore {
    
    /// Returns a dict where the key is the number of days from the start date (lowerBound) of dateRange, and the value is the daily total for the dietary energy on that day
//    static func dailyDietaryEnergyValues(
//        dateRange: ClosedRange<Date>,
//        energyUnit: EnergyUnit
//    ) async throws -> [Int: Double] {
//
//        let statisticsCollection = try await HealthStore.dailyStatistics(
//            for: .dietaryEnergyConsumed,
//            from: dateRange.lowerBound,
//            to: dateRange.upperBound
//        )
//
//        var samplesDict: [Int: Double] = [:]
//
//        let numberOfDays = dateRange.upperBound.numberOfDaysFrom(dateRange.lowerBound)
//
//        for i in 0...numberOfDays {
//            let date = dateRange.lowerBound.moveDayBy(i)
//            guard let statistics = statisticsCollection.statistics(for: date),
//                  let sumQuantity = statistics.sumQuantity()
//            else {
//                continue
//            }
//            let value = sumQuantity.doubleValue(for: energyUnit.healthKitUnit)
//            samplesDict[i] = value
//        }
//
//        return samplesDict
//    }
}


//MARK: - Quantities


private extension HealthStore {

    static func latestQuantity(
        for type: QuantityType,
        using unit: HKUnit?,
        excludingToday: Bool
    ) async throws -> Quantity? {
        do {
            let sample = try await latestQuantitySample(
                for: type.healthKitTypeIdentifier,
                excludingToday: excludingToday
            )
            let unit = unit ?? type.defaultUnit
            let quantity = sample.quantity.doubleValue(for: unit)
            let date = sample.startDate
            return Quantity(
                value: quantity,
                date: date
            )
        } catch {
            //TODO: This might be an indiciator of needing permissions
            return nil
        }
    }
    
    static func latestQuantitySample(
        for typeIdentifier: HKQuantityTypeIdentifier,
        excludingToday: Bool = false
    ) async throws -> HKQuantitySample {
        
        let type = HKSampleType.quantityType(forIdentifier: typeIdentifier)!
        
        let predicate: NSPredicate?
        if excludingToday {
            predicate = NSPredicate(format: "startDate < %@", Date().startOfDay as NSDate)
        } else {
            predicate = nil
        }
        let samplePredicates = [HKSamplePredicate.quantitySample(type: type, predicate: predicate)]
        let sortDescriptors: [SortDescriptor<HKQuantitySample>] = [SortDescriptor(\.startDate, order: .reverse)]
        let limit = 1
        
        let asyncQuery = HKSampleQueryDescriptor(
            predicates: samplePredicates,
            sortDescriptors: sortDescriptors,
            limit: limit
        )

        let results = try await asyncQuery.result(for: store)
        guard let sample = results.first else {
            throw HealthStoreError.couldNotGetSample
        }
        return sample
    }
}

//MARK: - Permissions
internal extension HealthStore {
    static func requestPermission(for type: QuantityType) async throws {
        try await requestPermissions(quantityTypeIdentifiers: [type.healthKitTypeIdentifier])
    }
    
    static func requestPermission(for characteristicType: HKCharacteristicTypeIdentifier) async throws {
        try await requestPermissions(characteristicTypeIdentifiers: [characteristicType])
    }

    static func requestPermissions(
        characteristicTypeIdentifiers: [HKCharacteristicTypeIdentifier] = [],
        quantityTypeIdentifiers: [HKQuantityTypeIdentifier] = []
    ) async throws {

        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthStoreError.healthKitNotAvailable
        }
        
        var readTypes: [HKObjectType] = []
        readTypes.append(contentsOf: quantityTypeIdentifiers.compactMap { HKQuantityType($0) })
        readTypes.append(contentsOf: characteristicTypeIdentifiers.compactMap { HKCharacteristicType($0) } )

        do {
            try await store.requestAuthorization(toShare: Set(), read: Set(readTypes))
        } catch {
            /// This error is not thrown if permissions have been revoked
            throw HealthStoreError.permissionsError(error)
        }
    }
}

extension HealthStore {

    static func dietaryEnergyTotalInKcal(for date: Date) async throws -> Double? {
        let dict = try await dailyDietaryEnergyTotalsInKcal(for: [date])
        return dict[date]
    }
    
    static func dailyDietaryEnergyTotalsInKcal(for dates: [Date]) async throws -> [Date: Double] {
        
        let sorted = dates.sorted()
        guard let firstDate = sorted.first, let lastDate = sorted.last else { return [:] }
        
        let statisticsCollection = try await HealthStore.dailyStatistics(
            for: .dietaryEnergyConsumed,
            from: firstDate,
            to: lastDate
        )

        var samplesDict: [Date: Double] = [:]
        
        for date in dates {
            guard let statistics = statisticsCollection.statistics(for: date),
                  let sumQuantity = statistics.sumQuantity()
            else {
                continue
            }
            let value = sumQuantity.doubleValue(for: EnergyUnit.kcal.healthKitUnit)
            samplesDict[date] = value
        }
        
        return samplesDict
    }
    
    static func dailyStatistics(
        for typeIdentifier: HKQuantityTypeIdentifier,
        from startDate: Date,
        to endDate: Date
    ) async throws -> HKStatisticsCollection {
        
        /// Request for permissions. **Note:** an error is not thrown here if permissions are not granted or later revoked.
        try await HealthStore.requestPermissions(quantityTypeIdentifiers: [typeIdentifier])
        
        /// Always get samples up to the start of the next day, so that we get all of `date`'s results too
        let endDate = endDate.startOfDay.moveDayBy(1)
        
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        
        /// Create the query descriptor.
        let type = HKSampleType.quantityType(forIdentifier: typeIdentifier)!
        let samplesPredicate = HKSamplePredicate.quantitySample(type: type, predicate: datePredicate)
        
        /// We want the sum of each day
        let everyDay = DateComponents(day: 1)
        
        let asyncQuery = HKStatisticsCollectionQueryDescriptor(
            predicate: samplesPredicate,
            options: .cumulativeSum,
            anchorDate: endDate,
            intervalComponents: everyDay
        )
        return try await asyncQuery.result(for: HealthStore.store)
    }
}
