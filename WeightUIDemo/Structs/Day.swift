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

extension HealthDetails {
    var syncables: [any HealthKitSyncable] {
        [leanBodyMass, weight, height, fatPercentage]
    }
    
    var deletedHealthKitUUIDs: [UUID] {
        syncables
            .map { $0.deletedHealthKitMeasurements.compactMap { $0.healthKitUUID } }
            .flatMap { $0 }
    }
}

extension HealthDetails {
    mutating func syncWithHealthKit(
        type: HealthKitType,
        samples: [HKQuantitySample],
        toDelete: inout [HKQuantitySample],
        toExport: inout [any Measurable],
        settings: Settings
    ) {
        
        var syncable: (any HealthKitSyncable)? {
            get {
                switch type {
                case .weight:           weight
                case .leanBodyMass:     leanBodyMass
                case .height:           height
                case .fatPercentage:    fatPercentage
                default:                nil
                }
            }
            set {
                guard let newValue else { return }
                switch type {
                case .weight:
                    guard let weight = newValue as? Weight else { return }
                    self.weight = weight
                    
                case .leanBodyMass:
                    guard let leanBodyMass = newValue as? LeanBodyMass else { return }
                    self.leanBodyMass = leanBodyMass

                case .height:
                    guard let height = newValue as? Height else { return }
                    self.height = height

                case .fatPercentage:
                    guard let fatPercentage = newValue as? FatPercentage else { return }
                    self.fatPercentage = fatPercentage

                default:
                    break
                }
            }
        }
        
        syncable?.processHealthKitSamples(
            samples,
            for: date,
            toDelete: &toDelete,
            toExport: &toExport,
            settings: settings
        )

//        switch quantityType {
//        case .weight:
//            weight.processHealthKitSamples(samples, for: date, toDelete: &toDelete, toExport: &toExport, settings: settings)
//        case .leanBodyMass:
//            leanBodyMass.processHealthKitSamples(samples, for: date, toDelete: &toDelete, toExport: &toExport, settings: settings)
//        case .height:
//            height.processHealthKitSamples(samples, for: date, toDelete: &toDelete, toExport: &toExport, settings: settings)
//        case .fatPercentage:
//            fatPercentage.processHealthKitSamples(samples, for: date, toDelete: &toDelete, toExport: &toExport, settings: settings)
//        default:
//            break
//        }
    }
}
extension Day {
    mutating func fetchFromHealthKitIfNeeded(
        type: HealthKitType,
        using stats: HKStatisticsCollection
    ) async {
        
        let day = self
        
        switch type {

        case .restingEnergy:
            await healthDetails.maintenance.estimate.restingEnergy
                .fetchFromHealthKitIfNeeded(day: day, using: stats)

        case .activeEnergy:
            await healthDetails.maintenance.estimate.activeEnergy
                .fetchFromHealthKitIfNeeded(day: day, using: stats)

        case .dietaryEnergy:
            /// If we don't yet a have dietaryEnergyPoint for this date, create one
            if dietaryEnergyPoint == nil {
                /// First try grab the log value, then the healthKit value, otherwise not counting the day
                dietaryEnergyPoint = if let kcal = day.energyInKcal {
                    .init(date: day.date, kcal: kcal, source: .log)
                } else if let kcal = await HealthStore.dietaryEnergyTotalInKcal(for: day.date, using: stats) {
                    .init(date: day.date, kcal: kcal, source: .healthKit)
                } else {
                    .init(date: day.date, source: .notCounted)
                }
            } else {
                /// Otherwise update the kcals based on the source that the user has chosen
                await dietaryEnergyPoint?
                    .fetchFromHealthKitIfNeeded(day: day, using: stats)
            }

        default:
            break
        }
    }
}
