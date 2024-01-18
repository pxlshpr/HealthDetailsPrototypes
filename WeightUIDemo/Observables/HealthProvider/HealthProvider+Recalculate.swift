import SwiftUI
import HealthKit

extension HealthProvider {
    func recalculate(
        latestHealthDetails: [HealthDetail: DatedHealthData],
        settings: Settings,
        days: [Day]
    ) async {
        /// Do this before we calculate anything so that we have the latest available
        healthDetails.setLatestHealthDetails(latestHealthDetails)

        /// Recalculate LBM, fat percentage based on equations – before converting to their counterparts (otherwise we're calculating on possibly invalid values)
        await recalculateLeanBodyMasses()
        await recalculateFatPercentages()

        /// Convert LBM and fat percentage to their counterparts – before setting latest health details
        healthDetails.convertLeanBodyMassesToFatPercentages()
        healthDetails.convertFatPercentagesToLeanBodyMasses()

        /// Now recalculate Daily Values (do this after any lean body mass / fat percentage modifications have been done)
        healthDetails.recalculateDailyValues(using: settings)

        await recalculateMaintenance(days)
    }
}

extension HealthProvider {

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

    func recalculateMaintenance(_ days: [Day]) async {
        await recalculateEstimatedMaintenanace()

        await recalculateDietaryEnergy(days)
        /// [ ] If WeightChange is .usingPoints, either fetch each weight or fetch the moving average components and calculate the average
        /// [ ] Reclaculate Adaptive
        /// [ ] Recalculate Maintenance based on toggle + fallback thing
        
        healthDetails.maintenance.setKcal()
    }
    
    func recalculateDietaryEnergy(_ days: [Day]) async {
        /// [ ] If we don't have enough points for DietaryEnergyPoint, create them
        /// [ ] Choose `.healthKit` as the source for any new ones that we can't fetch a log value for
        
        
        /// [ ] For each DietaryEnergyPoint in adaptive, re-fetch if either log, or AppleHealth
        /// [ ] Recalculate DietaryEnergy
        print("🍏 recalculateDietaryEnergy() ...")
        let start = CFAbsoluteTimeGetCurrent()
        
        let interval = healthDetails.maintenance.adaptive.interval
        let date = healthDetails.date

        var points: [DietaryEnergyPoint] = []
        for index in 0..<interval.numberOfDays {
            let date = date.moveDayBy(-(index + 1))
            
            /// Fetch the point if it exists
            if let point = await HealthProvider.fetchBackendDietaryEnergyPoint(for: date) {
//                print("Fetched existing point for: \(date.shortDateString)")
                points.append(point)
            } else {
                let point = DietaryEnergyPoint(date: date, source: .notCounted)
                points.append(point)
            }
        }
        healthDetails.maintenance.adaptive.dietaryEnergy.kcalPerDay = HealthDetails.Maintenance.Adaptive.DietaryEnergy.calculateKcalPerDay(for: points)
        print("... 🍏 took \(CFAbsoluteTimeGetCurrent()-start)s")
    }
    
    func recalculateEstimatedMaintenanace() async {
        await recalculateRestingEnergy()
        await recalculateActiveEnergy()
        let estimate = healthDetails.maintenance.estimate
        guard let resting = estimate.restingEnergy.kcal,
              let active = estimate.activeEnergy.kcal else {
            healthDetails.maintenance.estimate.kcal = nil
            return
        }
        healthDetails.maintenance.estimate.kcal = resting + active
    }
    
    func recalculateRestingEnergy() async {
        let restingEnergy = healthDetails.maintenance.estimate.restingEnergy
        guard 
            restingEnergy.source == .equation, 
            let equation = restingEnergy.equation
        else { return }
        let kcal = await calculateRestingEnergyInKcal(using: equation)
        healthDetails.maintenance.estimate.restingEnergy.kcal = kcal
    }
    
    func recalculateActiveEnergy() async {
        let activeEnergy = healthDetails.maintenance.estimate.activeEnergy
        guard
            let restingEnergyInKcal = healthDetails.maintenance.estimate.restingEnergy.kcal,
            activeEnergy.source == .activityLevel,
            let activityLevel = activeEnergy.activityLevel
        else { return }
        
        let kcal = activityLevel.calculate(for: restingEnergyInKcal)
        healthDetails.maintenance.estimate.activeEnergy.kcal = kcal
    }
}
