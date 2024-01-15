import Foundation

extension HealthProvider {
    var currentOrLatestWeightInKg: Double? {
        healthDetails.weight.weightInKg ?? latest.weightWithDate?.weight.weightInKg
    }
    
    var currentOrLatestMaintenanceInKcal: Double? {
        healthDetails.maintenance.kcal ?? latest.maintenanceWithDate?.maintenance.kcal
    }
    
    var currentOrLatestLeanBodyMassInKg: Double? {
        healthDetails.leanBodyMass.leanBodyMassInKg ?? latest.leanBodyMassWithDate?.leanBodyMass.leanBodyMassInKg
    }
    
    var currentOrLatestHeightInCm: Double? {
        healthDetails.height.heightInCm ?? latest.heightWithDate?.height.heightInCm
    }
    
    var biologicalSex: BiologicalSex {
        healthDetails.biologicalSex
    }
    
    var ageInYears: Int? {
        healthDetails.ageInYears
    }
    
}
