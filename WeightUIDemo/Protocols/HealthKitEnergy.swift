import Foundation
import HealthKit

protocol HealthKitEnergy {
    var healthKitFetchSettings: HealthKitFetchSettings? { get }
    var isHealthKitSourced: Bool { get }
    var kcal: Double? { get set }
    var energyType: EnergyType { get }
}

extension HealthKitEnergy {

    mutating func mock_fetchFromHealthKitIfNeeded(for date: Date, using statisticsCollection: HKStatisticsCollection) async {
        /// Test with maximum possible interval
        self.kcal = await HealthStore.energy(
            energyType,
            for: .init(2, .week),
            on: date,
            using: statisticsCollection
        )
    }
    
    mutating func fetchFromHealthKitIfNeeded(date: Date) async {
        guard isHealthKitSourced, let healthKitFetchSettings else { return }
        let kcal = switch healthKitFetchSettings.intervalType {
        case .average:
            await HealthStore.energy(
                energyType,
                for: healthKitFetchSettings.interval,
                on: date
            )
        case .sameDay:
            await HealthStore.energy(energyType, on: date)
        case .previousDay:
            await HealthStore.energy(energyType, on: date.moveDayBy(-1))
        }
        self.kcal = kcal
    }
}
