import Foundation
import HealthKit

protocol HealthKitEnergy: HealthKitFetchable {
    var healthKitFetchSettings: HealthKitFetchSettings? { get }
    var isHealthKitSourced: Bool { get }
    var kcal: Double? { get set }
    var energyType: EnergyType { get }
}

extension HealthKitEnergy {

    mutating func mock_fetchFromHealthKitIfNeeded(
        for date: Date,
        using stats: HKStatisticsCollection
    ) async {
        /// Test with maximum possible interval
        self.kcal = await HealthStore.energy(
            energyType,
            for: .init(2, .week),
            on: date,
            using: stats
        )
    }
    
    mutating func fetchFromHealthKitIfNeeded(
        day: Day,
        using stats: HKStatisticsCollection
    ) async {
        guard isHealthKitSourced, let healthKitFetchSettings else { return }
        let kcal = switch healthKitFetchSettings.intervalType {
        case .average:
            await HealthStore.energy(
                energyType,
                for: healthKitFetchSettings.interval,
                on: day.date,
                using: stats
            )
        case .sameDay:
            await HealthStore.energy(energyType, on: day.date)
        case .previousDay:
            await HealthStore.energy(energyType, on: day.date.moveDayBy(-1))
        }
        self.kcal = kcal
    }
}
