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
    
    var replacementsForMissing = ReplacementsForMissing()
}

extension HealthDetails {
    struct ReplacementsForMissing: Hashable, Codable {
        var datedWeight: DatedWeight?
        var datedHeight: DatedHeight?
        var datedLeanBodyMass: DatedLeanBodyMass?
        var datedFatPercentage: DatedFatPercentage?
        var datedPregnancyStatus: DatedPregnancyStatus?
        var datedMaintenance: DatedMaintenance?
    }
}

extension HealthDetails.ReplacementsForMissing {
    func has(_ healthDetail: HealthDetail) -> Bool {
        switch healthDetail {
        case .weight:           datedWeight != nil
        case .height:           datedHeight != nil
        case .leanBodyMass:     datedLeanBodyMass != nil
        case .preganancyStatus: datedPregnancyStatus != nil
        case .fatPercentage:    datedFatPercentage != nil
        case .maintenance:      datedMaintenance != nil
        default:                false
        }
    }
}

extension HealthDetails {
    
    func extractReplacementsForMissing(from dict: [HealthDetail : DatedHealthData]) -> ReplacementsForMissing {
        ReplacementsForMissing(
            datedWeight: !hasSet(.weight) ? dict.datedWeight : nil,
            datedHeight: !hasSet(.height) ? dict.datedHeight : nil,
            datedLeanBodyMass: !hasSet(.leanBodyMass) ? dict.datedLeanBodyMass : nil,
            datedFatPercentage: !hasSet(.fatPercentage) ? dict.datedFatPercentage : nil,
            datedPregnancyStatus: !hasSet(.preganancyStatus) ? dict.datedPregnancyStatus : nil,
            datedMaintenance: !hasSet(.maintenance) ? dict.datedMaintenance : nil
        )
    }
}

struct DatedWeight: Hashable, Codable {
    let date: Date
    var weight: HealthDetails.Weight
}

struct DatedMaintenance: Hashable, Codable {
    let date: Date
    var maintenance: HealthDetails.Maintenance
}

struct DatedHeight: Hashable, Codable {
    let date: Date
    var height: HealthDetails.Height
}

struct DatedLeanBodyMass: Hashable, Codable {
    let date: Date
    var leanBodyMass: HealthDetails.LeanBodyMass
}

struct DatedFatPercentage: Hashable, Codable {
    let date: Date
    var fatPercentage: HealthDetails.FatPercentage
}

struct DatedPregnancyStatus: Hashable, Codable {
    let date: Date
    var pregnancyStatus: PregnancyStatus
}
