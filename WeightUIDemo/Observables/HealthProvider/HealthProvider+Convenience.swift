import Foundation

extension HealthProvider {
    var currentOrLatestWeightInKg: Double? {
        healthDetails.weight.weightInKg ?? latest.datedWeight?.weight.weightInKg
    }
    
    var currentOrLatestLeanBodyMassInKg: Double? {
        healthDetails.leanBodyMass.leanBodyMassInKg ?? latest.datedLeanBodyMass?.leanBodyMass.leanBodyMassInKg
    }
    
    var currentOrLatestHeightInCm: Double? {
        healthDetails.height.heightInCm ?? latest.datedHeight?.height.heightInCm
    }
    
    var biologicalSex: BiologicalSex {
        healthDetails.biologicalSex
    }
    
    var ageInYears: Int? {
        healthDetails.ageInYears
    }
    
}
