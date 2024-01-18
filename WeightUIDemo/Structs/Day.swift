import Foundation

struct Day: Codable, Hashable {
    let date: Date
    var healthDetails: HealthDetails
    var dietaryEnergyPoint: DietaryEnergyPoint?
    var energyInKcal: Double?
    
    init(date: Date) {
        self.date = date
        self.healthDetails = HealthDetails(date: date)
    }
}

import HealthKit

extension Day {
    mutating func fetchFromHealthKitIfNeeded(
        quantityType: QuantityType,
        using stats: HKStatisticsCollection
    ) async {
        let day = self
        switch quantityType {
        case .restingEnergy:
            await healthDetails.maintenance.estimate.restingEnergy
                .fetchFromHealthKitIfNeeded(day: day, using: stats)
        case .activeEnergy:
            await healthDetails.maintenance.estimate.activeEnergy
                .fetchFromHealthKitIfNeeded(day: day, using: stats)
        case .dietaryEnergy:
            await dietaryEnergyPoint?
                .fetchFromHealthKitIfNeeded(day: day, using: stats)
        default:
            break
        }
    }
}
