import Foundation

extension HealthProvider {
    
    var biologicalSex: BiologicalSex {
        healthDetails.biologicalSex
    }
    
    var ageInYears: Int? {
        healthDetails.ageInYears
    }
    
}

extension HealthDetails {
    var currentOrLatestWeightInKg: Double? {
        weight.weightInKg ?? replacementsForMissing.datedWeight?.weight.weightInKg
    }
    
    var currentOrLatestLeanBodyMassInKg: Double? {
        leanBodyMass.leanBodyMassInKg ?? replacementsForMissing.datedLeanBodyMass?.leanBodyMass.leanBodyMassInKg
    }
    
    var currentOrLatestHeightInCm: Double? {
        height.heightInCm ?? replacementsForMissing.datedHeight?.height.heightInCm
    }
    
    var hasIncompatibleLeanBodyMassAndFatPercentageWithWeight: Bool {
        guard let fatPercentage = currentOrLatestFatPercentage,
              let weight = currentOrLatestWeightInKg,
              let leanBodyMass = currentOrLatestLeanBodyMassInKg else {
            return false
        }
        
        let calculatedLeanBodyMass = calculateLeanBodyMass(
            fatPercentage: fatPercentage,
            weightInKg: weight
        )
        return calculatedLeanBodyMass != leanBodyMass
    }
    
    var currentOrLatestFatPercentage: Double? {
        fatPercentage.fatPercentage ?? replacementsForMissing.datedFatPercentage?.fatPercentage.fatPercentage
    }
}
