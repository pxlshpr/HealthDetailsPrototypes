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
}

extension HealthDetails {
    struct Latest: Hashable, Codable {
        var weight: DatedWeight?
        var height: DatedHeight?
        var leanBodyMass: DatedLeanBodyMass?
        var fatPercentage: DatedFatPercentage?
        var pregnancyStatus: DatedPregnancyStatus?
    }
}

extension HealthDetails {
    func extractMissingLatestHealthDetails(from dict: [HealthDetail : DatedHealthData]) -> Latest {
        Latest(
            weight: !hasSet(.weight) ? dict.datedWeight : nil,
            height: !hasSet(.height) ? dict.datedHeight : nil,
            leanBodyMass: !hasSet(.leanBodyMass) ? dict.datedLeanBodyMass : nil,
            fatPercentage: !hasSet(.fatPercentage) ? dict.datedFatPercentage : nil,
            pregnancyStatus: !hasSet(.preganancyStatus) ? dict.datedPregnancyStatus : nil
        )
    }
}

struct DatedWeight: Hashable, Codable {
    let date: Date
    let weight: HealthDetails.Weight
}

struct DatedHeight: Hashable, Codable {
    let date: Date
    let height: HealthDetails.Height
}

struct DatedLeanBodyMass: Hashable, Codable {
    let date: Date
    let leanBodyMass: HealthDetails.LeanBodyMass
}

struct DatedFatPercentage: Hashable, Codable {
    let date: Date
    let fatPercentage: HealthDetails.FatPercentage
}

struct DatedPregnancyStatus: Hashable, Codable {
    let date: Date
    let pregnancyStatus: PregnancyStatus
}
