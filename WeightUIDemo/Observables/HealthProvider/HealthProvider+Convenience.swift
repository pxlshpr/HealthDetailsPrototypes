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
}
