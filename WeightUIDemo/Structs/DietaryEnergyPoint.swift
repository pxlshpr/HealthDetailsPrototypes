import Foundation
import HealthKit

struct DietaryEnergyPoint: Hashable, Codable {
    var date: Date
    var kcal: Double?
    var source: DietaryEnergyPointSource
}

protocol HealthKitFetchable {
    mutating func fetchFromHealthKitIfNeeded(day: Day, using stats: HKStatisticsCollection) async
}

extension DietaryEnergyPoint: HealthKitFetchable {
    mutating func fetchFromHealthKitIfNeeded(day: Day, using stats: HKStatisticsCollection) async {
        switch source {
        case .healthKit:
            kcal = await HealthStore.dietaryEnergyTotalInKcal(for: day.date, using: stats)
        case .log:
            kcal = day.energyInKcal
        default:
            break
        }
    }
}

extension Array where Element == DietaryEnergyPoint {
    mutating func fillAverages() {
        guard let averageOfPointsNotUsingAverage else { return }
        for i in 0..<count {
            /// Only fill with average if there is no value for it or it already has a type of `average`
            guard self[i].source == .notCounted else { continue }
            self[i].kcal = averageOfPointsNotUsingAverage
        }
    }
    
    var averageOfPointsNotUsingAverage: Double? {
        let values = self
            .filter { $0.source != .notCounted }
            .compactMap { $0.kcal }
        guard !values.isEmpty else { return nil }
        let sum = values.reduce(0) { $0 + $1 }
        return Double(sum) / Double(values.count)
    }
    
    var kcalPerDay: Double? {
        let values = self
            .compactMap { $0.kcal }
        guard !values.isEmpty else { return nil }
        let sum = values.reduce(0) { $0 + $1 }
        return Double(sum) / Double(values.count)
    }
    
    var totalInKcal: Double? {
        guard !isEmpty else { return nil }
        return self
            .compactMap { $0.kcal }
            .reduce(0) { $0 + $1 }
    }
}
