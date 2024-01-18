import SwiftUI

extension HealthProvider {
    
    func recalculate() async {
        let settings = settingsProvider.settings

        /// [ ] Recalculate LBM, fat percentage based on equations and based on each other (simply recreate these if we have a weight for the day, otherwise removing them)
        await recalculateLeanBodyMasses()
        await recalculateFatPercentages()
        healthDetails.convertLeanBodyMassesToFatPercentages()
        healthDetails.convertFatPercentagesToLeanBodyMasses()
        
        /// Now recalculate Daily Values (do this after any lean body mass / fat percentage modifications have been done)
        healthDetails.recalculateDailyValues(using: settings)

        await recalculateMaintenance()
    }
    
    func recalculateLeanBodyMasses() async {
        let initial = healthDetails.leanBodyMass
        for (index, measurement) in initial.measurements.enumerated() {
            guard measurement.source == .equation,
                  let equation = measurement.equation
            else { continue }
            
            /// If we're unable to calculate the lean body mass for this measurement any more—remove it
            guard let kg = await calculateLeanBodyMassInKg(using: equation) else {
                healthDetails.leanBodyMass.measurements.remove(at: index)
                return
            }
            
            /// Otherwise re-set the existing value with the calculated one in case it changed
            healthDetails.leanBodyMass.measurements[index].leanBodyMassInKg = kg
        }
        
        /// Only continue if changes were actually made
        guard healthDetails.leanBodyMass != initial else { return }

        /// Re-set the daily value based on the new measurements
        let dailyValue = settingsProvider.settings.dailyValueType(for: .leanBodyMass)
        healthDetails.leanBodyMass.setDailyValue(for: dailyValue)
    }
    
    func recalculateFatPercentages() async {
        let initial = healthDetails.fatPercentage
        for (index, measurement) in initial.measurements.enumerated() {
            guard measurement.source == .equation,
                  let equation = measurement.equation
            else { continue }
            
            /// If we're unable to calculate the fat percentage for this measurement any more—remove it
            guard let percent = await calculateFatPercentageInPercent(using: equation) else {
                healthDetails.fatPercentage.measurements.remove(at: index)
                return
            }
            
            /// Otherwise re-set the existing value with the calculated one in case it changed
            healthDetails.fatPercentage.measurements[index].percent = percent
        }
        
        /// Only continue if changes were actually made
        guard healthDetails.fatPercentage != initial else { return }

        /// Re-set the daily value based on the new measurements
        let dailyValue = settingsProvider.settings.dailyValueType(for: .fatPercentage)
        healthDetails.fatPercentage.setDailyValue(for: dailyValue)
    }

    func recalculateMaintenance() async {
        /// [ ] Recalculate resting energy
        /// [ ] Recalculate active energy
        /// [ ] For each DietaryEnergyPoint in adaptive, re-fetch if either log, or AppleHealth
        /// [ ] Recalculate DietaryEnergy
        /// [ ] If WeightChange is .usingPoints, either fetch each weight or fetch the moving average components and calculate the average
        /// [ ] Reclaculate Adaptive
        /// [ ] Recalculate Maintenance based on toggle + fallback thing
    }
}
