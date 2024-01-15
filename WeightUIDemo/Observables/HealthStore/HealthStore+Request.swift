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
    static func weightMeasurements(
        in unit: BodyMassUnit = .kg,
        from startDate: Date? = nil
    ) async -> [HKQuantitySample] {
        do {
            return try await HealthKitQuantityRequest(.weight, unit.healthKitUnit).allSamples(startingFrom: startDate) ?? []
        } catch {
            return []
        }
    }
    
    static func leanBodyMassMeasurements(
        in unit: BodyMassUnit = .kg,
        from startDate: Date? = nil
    ) async -> [HKQuantitySample] {
        do {
            return try await HealthKitQuantityRequest(.leanBodyMass, unit.healthKitUnit).allSamples(startingFrom: startDate) ?? []
        } catch {
            return []
        }
    }
    
    static func heightMeasurements(
        in unit: HeightUnit = .cm,
        from startDate: Date? = nil
    ) async -> [HKQuantitySample] {
        do {
            return try await HealthKitQuantityRequest(.height, unit.healthKitUnit).allSamples(startingFrom: startDate) ?? []
        } catch {
            return []
        }
    }
}
