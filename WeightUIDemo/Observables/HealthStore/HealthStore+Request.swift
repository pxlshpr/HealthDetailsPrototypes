import HealthKit
import PrepShared

extension HealthStore {
    
    static func biologicalSex() async throws -> HKBiologicalSex? {
        try store.biologicalSex().biologicalSex
    }
    
    static func dateOfBirthComponents() async throws -> DateComponents? {
        try store.dateOfBirthComponents()
    }

    static func energy(
        _ type: EnergyType,
        for interval: HealthInterval = .init(0, .day),
        on date: Date = Date.now,
        in unit: EnergyUnit = .kcal
    ) async -> Double {
        await HealthKitEnergyRequest(type, unit, interval, date)
            .dailyAverage()
    }
    
    static func energy(
        _ type: EnergyType,
        for interval: HealthInterval = .init(0, .day),
        on date: Date = Date.now,
        in unit: EnergyUnit = .kcal,
        using statisticsCollection: HKStatisticsCollection
    ) async -> Double {
        await HealthKitEnergyRequest(type, unit, interval, date)
            .dailyAverage(using: statisticsCollection)
    }
}


extension HealthStore {
    
    static func samples(
        for type: HealthKitType,
        from startDate: Date? = nil,
        to endDate: Date? = nil
    ) async -> [HKQuantitySample] {
        do {
            return try await HealthKitQuantityRequest(
                type,
                type.defaultUnit
            ).allSamples(
                startingFrom: startDate,
                to: endDate
            ) ?? []
        } catch {
            return []
        }
    }
    
    static func mostRecentSample(
        for type: HealthKitType,
        excluding uuidsToExclude: [UUID]
    ) async -> HKQuantitySample? {
        do {
            return try await HealthKitQuantityRequest(
                type,
                type.defaultUnit)
            .mostRecentSample(excluding: uuidsToExclude)
        } catch {
            return nil
        }
    }
}
