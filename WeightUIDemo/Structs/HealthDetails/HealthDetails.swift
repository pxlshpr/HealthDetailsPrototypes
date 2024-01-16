import Foundation
import PrepShared

struct HealthDetails: Hashable, Codable {
    
    let date: Date
    
    var maintenance = Maintenance()
    
    var weight = Weight()
    var height = Height()
    var leanBodyMass = LeanBodyMass()
    var fatPercentage = FatPercentage()
    var pregnancyStatus: PregnancyStatus = .notSet

    var dateOfBirthComponents: DateComponents?
    var biologicalSex: BiologicalSex = .notSet
    var smokingStatus: SmokingStatus = .notSet
    
    struct Latest: Hashable, Codable {
        var weight: Weight?
        var height: Height?
        var leanBodyMass: LeanBodyMass?
        var fatPercentage: FatPercentage?
        var pregnancyStatus: PregnancyStatus?
    }
}
