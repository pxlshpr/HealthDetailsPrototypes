import Foundation
import PrepShared

extension HealthDetails {
    struct Maintenance: Hashable, Codable {
        
        var type: MaintenanceType = .estimated
        var kcal: Double?
        var adaptive = Adaptive()
        var estimate = Estimate()
        var useEstimateAsFallback: Bool = true
        var hasConfigured: Bool = false
        
        struct Adaptive: Hashable, Codable {
            var kcal: Double?
            var interval: HealthInterval
            
            var dietaryEnergy = DietaryEnergy()
            var weightChange = WeightChange()
            
            init(
                kcal: Double? = nil,
                interval: HealthInterval = .init(1, .week),
                dietaryEnergyPoints points: [DietaryEnergyPoint] = [],
                weightChange: WeightChange = WeightChange()
            ) {
                self.kcal = kcal
                self.interval = interval
                self.dietaryEnergy = .init(points: points)
                self.weightChange = weightChange

                self.kcal = self.calculateIfValid()
            }

            struct DietaryEnergy: Hashable, Codable {
                var kcalPerDay: Double?

                init(kcalPerDay: Double? = nil) {
                    self.kcalPerDay = kcalPerDay
                }
                
                init(points: [DietaryEnergyPoint]) {
                    var points = points
                    points.fillAverages()
                    self.kcalPerDay = points.kcalPerDay
                }
                
                static func calculateKcalPerDay(for points: [DietaryEnergyPoint]) -> Double? {
                    var points = points
                    points.fillAverages()
                    return points.kcalPerDay
                }
            }
        }
        
        struct Estimate: Hashable, Codable {
            var kcal: Double?
            var restingEnergy = RestingEnergy()
            var activeEnergy = ActiveEnergy()
            
            struct RestingEnergy: Hashable, Codable {
                var kcal: Double? = nil
                var source: RestingEnergySource = .equation
                var equation: RestingEnergyEquation? = .katchMcardle
                var preferLeanBodyMass: Bool = true
                var healthKitFetchSettings: HealthKitFetchSettings?
            }
            
            struct ActiveEnergy: Hashable, Codable {
                var kcal: Double? = nil
                var source: ActiveEnergySource = .activityLevel
                var activityLevel: ActivityLevel? = .lightlyActive
                var healthKitFetchSettings: HealthKitFetchSettings?
            }
            
        }
    }
}

extension HealthDetails.Maintenance.Estimate.RestingEnergy: HealthKitEnergy {
    var isHealthKitSourced: Bool { source == .healthKit }
    var energyType: EnergyType { .resting }
}

extension HealthDetails.Maintenance.Estimate.ActiveEnergy: HealthKitEnergy {
    var isHealthKitSourced: Bool { source == .healthKit }
    var energyType: EnergyType { .active }
}


extension HealthDetails.Maintenance.Adaptive {
//    static func calculate(
//        weightChange: WeightChange,
//        dietaryEnergy: DietaryEnergy,
//        interval: HealthInterval
//    ) -> Result<Double, MaintenanceCalculationError> {
//        
//        guard let weightDeltaInKcal = weightChange.energyEquivalentInKcal,
//              let dietaryEnergyTotal = dietaryEnergy.totalInKcal
//        else {
//            return switch (weightChange.isEmpty, dietaryEnergy.isEmpty) {
//            case (true, false): .failure(.noWeightData)
//            case (false, true): .failure(.noNutritionData)
//            default:            .failure(.noWeightOrNutritionData)
//            }
//        }
//        
//        let value = (dietaryEnergyTotal - weightDeltaInKcal) / Double(interval.numberOfDays)
//        
//        guard value > 0 else {
//            return .failure(.weightChangeExceedsNutrition)
//        }
//        
//        return .success(max(value, 0))
//    }
    
//    static func calculate(
//        weightChange: WeightChange,
//        dietaryEnergyPoints: [DietaryEnergyPoint],
//        interval: HealthInterval
//    ) -> Result<Double, MaintenanceCalculationError> {
//        
//        guard let weightDeltaInKcal = weightChange.energyEquivalentInKcal,
//              let dietaryEnergyTotal = dietaryEnergyPoints.totalInKcal
//        else {
//            return switch (weightChange.isEmpty, dietaryEnergyPoints.isEmpty) {
//            case (true, false): .failure(.noWeightData)
//            case (false, true): .failure(.noNutritionData)
//            default:            .failure(.noWeightOrNutritionData)
//            }
//        }
//        
//        let value = (dietaryEnergyTotal - weightDeltaInKcal) / Double(interval.numberOfDays)
//        
//        guard value > 0 else {
//            return .failure(.weightChangeExceedsNutrition)
//        }
//        
//        return .success(max(value, 0))
//    }

    static func calculate(
        interval: HealthInterval,
        weightChange: WeightChange,
        dietaryEnergy: DietaryEnergy
    ) -> Double? {
        guard let weightDeltaInKcal = weightChange.energyEquivalentInKcal,
              let kcalPerDay = dietaryEnergy.kcalPerDay else {
            return nil
        }
        let totalKcal = kcalPerDay * Double(interval.numberOfDays)
        return (totalKcal - weightDeltaInKcal) / Double(interval.numberOfDays)
    }
    
    func calculateIfValid() -> Double? {
        guard let kcal = Self.calculate(
            interval: interval,
            weightChange: weightChange,
            dietaryEnergy: dietaryEnergy
        ) else { return nil }

        guard kcal >= MinimumAdaptiveEnergyInKcal else { return nil }
        return kcal
    }
    
    static func minimumEnergyString(in energyUnit: EnergyUnit) -> String {
        let converted = EnergyUnit.kcal.convert(MinimumAdaptiveEnergyInKcal, to: energyUnit)
        return "\(converted.formattedEnergy) \(energyUnit.abbreviation)"
    }
}

extension HealthDetails.Maintenance {
    func valueString(in unit: EnergyUnit) -> String {
        kcal.valueString(convertedFrom: .kcal, to: unit)
    }
}

extension HealthDetails.Maintenance.Adaptive {
    mutating func setKcal() {
        kcal = calculateIfValid()
    }
}
extension HealthDetails.Maintenance.Estimate {
    mutating func setKcal() {
        kcal = if let resting = restingEnergy.kcal, let active = activeEnergy.kcal {
            resting + active
        } else {
            nil
        }
    }
}

extension HealthDetails.Maintenance {
    mutating func setKcal() {
        kcal = switch type {
        case .adaptive:
            if let adaptive = adaptive.kcal {
                adaptive
            } else {
                if useEstimateAsFallback {
                    estimate.kcal
                } else {
                    nil
                }
            }
        case .estimated:
            estimate.kcal
        }
    }
}
