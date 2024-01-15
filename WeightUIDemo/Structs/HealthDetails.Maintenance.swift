import Foundation
import PrepShared

extension HealthDetails {
    struct Maintenance: Hashable, Codable {
        
        var type: MaintenanceType = .estimated
        var kcal: Double?
        var adaptive = Adaptive()
        var estimate = Estimate()
        var useEstimateAsFallback: Bool = true
        
        struct Adaptive: Hashable, Codable {
            var kcal: Double?
            var error: MaintenanceCalculationError?
            var interval: HealthInterval
            
            var dietaryEnergy = DietaryEnergy()
            var weightChange = WeightChange()
            
            init(
                kcal: Double? = nil,
                interval: HealthInterval = .init(1, .week),
                dietaryEnergy: DietaryEnergy = DietaryEnergy(),
                weightChange: WeightChange = WeightChange()
            ) {
                self.kcal = kcal
                self.interval = interval
                self.dietaryEnergy = dietaryEnergy
                self.weightChange = weightChange
                
                let result = Self.calculate(
                    weightChange: weightChange,
                    dietaryEnergy: dietaryEnergy,
                    interval: interval
                )
                switch result {
                case .success(let value):
                    self.kcal = value
                    self.error = nil
                case .failure(let error):
                    self.kcal = nil
                    self.error = error
                }
            }
            
            struct DietaryEnergy: Hashable, Codable {
                var kcalPerDay: Double?
                var points: [DietaryEnergyPoint]
                
                init(points: [DietaryEnergyPoint] = []) {
                    var points = points
                    points.fillAverages()
                    self.points = points
                    self.kcalPerDay = points.average
                }
                
                var isEmpty: Bool {
                    !points.contains(where: { $0.kcal != nil })
                }
                
                var totalInKcal: Double? {
                    guard !isEmpty else { return nil }
                    return points
                        .compactMap { $0.kcal }
                        .reduce(0) { $0 + $1 }
                }
            }
        }
        
        struct Estimate: Hashable, Codable {
            var kcal: Double?
            var restingEnergy = RestingEnergy()
            var activeEnergy = ActiveEnergy()
            
            struct RestingEnergy: HealthKitFetchable, Hashable, Codable {
                var kcal: Double? = nil
                var source: RestingEnergySource = .equation
                
                var equation: RestingEnergyEquation = .katchMcardle
                var healthKitFetchSettings = HealthKitFetchSettings()
                
                var isHealthKitSourced: Bool { source == .healthKit }
                var energyType: EnergyType { .resting }
            }

            struct ActiveEnergy: HealthKitFetchable, Hashable, Codable {
                var kcal: Double? = nil
                var source: ActiveEnergySource = .activityLevel
                
                var activityLevel: ActivityLevel = .lightlyActive
                var healthKitFetchSettings = HealthKitFetchSettings()

                var isHealthKitSourced: Bool { source == .healthKit }
                var energyType: EnergyType { .active }
            }
            
        }
    }
}

extension HealthDetails.Maintenance.Adaptive {
    static func calculate(
        weightChange: WeightChange,
        dietaryEnergy: DietaryEnergy,
        interval: HealthInterval
    ) -> Result<Double, MaintenanceCalculationError> {
        
        guard let weightDeltaInKcal = weightChange.energyEquivalentInKcal,
              let dietaryEnergyTotal = dietaryEnergy.totalInKcal
        else {
            return switch (weightChange.isEmpty, dietaryEnergy.isEmpty) {
            case (true, false): .failure(.noWeightData)
            case (false, true): .failure(.noNutritionData)
            default:            .failure(.noWeightOrNutritionData)
            }
        }
        
        let value = (dietaryEnergyTotal - weightDeltaInKcal) / Double(interval.numberOfDays)
        
        guard value > 0 else {
            return .failure(.weightChangeExceedsNutrition)
        }
        
        return .success(max(value, 0))
    }
}

extension HealthDetails.Maintenance {
    func valueString(in unit: EnergyUnit) -> String {
        kcal.valueString(convertedFrom: .kcal, to: unit)
    }
}
