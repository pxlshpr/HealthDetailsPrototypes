import HealthKit
import PrepShared

extension HealthStore {
    
    static func latestDayOfWeightQuantities(
        in unit: BodyMassUnit = .kg,
        for date: Date = Date.now
    ) async throws -> [HealthKitMeasurement]? {
        try await HealthKitQuantityRequest(.weight, unit.healthKitUnit)
            .mostRecentDaysQuantities(to: date)?
            .removingDuplicateQuantities()
    }

    static func weightQuantities(
        in unit: BodyMassUnit = .kg,
        on date: Date
    ) async throws -> [HealthKitMeasurement]? {
        try await HealthKitQuantityRequest(.weight, unit.healthKitUnit)
            .daysQuantities(for: date)
    }

    static func weightQuantities(
        in unit: BodyMassUnit = .kg,
        for range: ClosedRange<Date>
    ) async throws -> [HealthKitMeasurement]? {
        try await HealthKitQuantityRequest(.weight, unit.healthKitUnit)
            .daysQuantities(for: range)
    }

    static func weight(
        in unit: BodyMassUnit = .kg,
        for date: Date = Date.now
    ) async throws -> HealthKitMeasurement? {
        try await HealthKitQuantityRequest(.weight, unit.healthKitUnit)
            .mostRecentOrEarliestAvailable(to: date)
    }

    static func leanBodyMass(
        in unit: BodyMassUnit = .kg,
        for date: Date = Date.now
    ) async throws -> HealthKitMeasurement? {
        try await HealthKitQuantityRequest(.leanBodyMass, unit.healthKitUnit)
            .mostRecentOrEarliestAvailable(to: date)
    }

    static func height(
        in unit: HeightUnit = .cm,
        for date: Date = Date.now
    ) async throws -> HealthKitMeasurement? {
        try await HealthKitQuantityRequest(.height, unit.healthKitUnit)
            .mostRecentOrEarliestAvailable(to: date)
    }

    static func biologicalSex() async throws -> HKBiologicalSex? {
        try await requestPermission(for: .biologicalSex)
        return try store.biologicalSex().biologicalSex
    }
    
    static func dateOfBirthComponents() async throws -> DateComponents? {
        try await requestPermission(for: .dateOfBirth)
        return try store.dateOfBirthComponents()
    }

    static func restingEnergy(
        for interval: HealthInterval = .init(0, .day),
        on date: Date = Date.now,
        in unit: EnergyUnit = .kcal
    ) async throws -> Double {
        try await HealthKitEnergyRequest(.resting, unit, interval, date)
            .dailyAverage()
    }
    
    static func activeEnergy(
        for interval: HealthInterval = .init(0, .day),
        on date: Date = Date.now,
        in unit: EnergyUnit = .kcal
    ) async throws -> Double {
        try await HealthKitEnergyRequest(.active, unit, interval, date)
            .dailyAverage()
    }
}

extension HealthStore {
    static func allWeightsQuantities(
        in unit: BodyMassUnit = .kg,
        startingFrom startDate: Date? = nil
    ) async -> [HealthKitMeasurement] {
        do {
            guard let measurements = try await HealthKitQuantityRequest(
                .weight,
                unit.healthKitUnit
            ).allQuantities(startingFrom: startDate) else {
                return []
            }
            return measurements
        } catch {
            return []
        }
    }
}
