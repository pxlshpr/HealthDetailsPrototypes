import HealthKit
import PrepShared

public class HealthStore {
    
    internal static let shared = HealthStore()
    internal static let store: HKHealthStore = HKHealthStore()
    
    public static var defaultUnitHandler: ((QuantityType) -> HKUnit)? = nil
}

internal extension HealthStore {

    static func requestPermissions() async throws {

        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthStoreError.healthKitNotAvailable
        }
        
        let readTypes: [HKObjectType] = [
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.basalEnergyBurned),
            HKQuantityType(.bodyMass),
            HKQuantityType(.height),
            HKQuantityType(.leanBodyMass),
            HKQuantityType(.bodyFatPercentage),
            HKCharacteristicType(.dateOfBirth),
            HKCharacteristicType(.biologicalSex),
        ]

        let writeTypes: [HKQuantityType] = [
            HKQuantityType(.bodyMass),
            HKQuantityType(.height),
            HKQuantityType(.leanBodyMass),
            HKQuantityType(.bodyFatPercentage),
        ]

        do {
            try await store.requestAuthorization(
                toShare: Set(writeTypes),
                read: Set(readTypes)
            )
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
        guard
            let firstDate = sorted.first?.startOfDay,
            let lastDate = sorted.last?.endOfDay
        else { return [:] }
        
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
