import Foundation

//extension HealthProvider {
//    func setLatest(_ latest: [HealthDetail : DatedHealthData]) {
//        self.latest = latest
//        healthDetails.bringForwardNonTemporalHealthDetails(from: latest)
//    }
//}

extension HealthDetails {
    mutating func setLatestHealthDetails(_ latest: [HealthDetail : DatedHealthData]) {

        /// Get any missing (temporal) health details from the dict, so that we can use them in equations etc
        self.replacementsForMissing = extractReplacementsForMissing(from: latest)

        /// Bring forward any non-temporal health details form the dict, so that we explicitly fill in the gaps with the assumption that they had not changed
        bringForwardNonTemporalHealthDetails(from: latest)
    }
}

extension HealthDetails {
    
    mutating func bringForwardNonTemporalHealthDetails(from latest: [HealthDetail : DatedHealthData] ) {
        if !hasSet(.age), let components = latest.dateOfBirthComponents {
            self.dateOfBirthComponents = components
        }
        if !hasSet(.biologicalSex), let biologicalSex = latest.biologicalSex {
            self.biologicalSex = biologicalSex
        }
        if !hasSet(.smokingStatus), let smokingStatus = latest.smokingStatus {
            self.smokingStatus = smokingStatus
        }
    }

//    func populateLatestDict(_ dict: inout [HealthDetail : DatedHealthData]) {
//        for healthDetail in HealthDetail.allCases {
//            guard !dict.keys.contains(healthDetail),
//                  hasSet(healthDetail),
//                  let data = data(for: healthDetail)
//            else { continue }
//            dict[healthDetail] = (date, data)
//        }
//    }
}

typealias DatedHealthData = (date: Date, data: Any)

extension Dictionary where Key == HealthDetail, Value == DatedHealthData {
    mutating func setHealthDetails(from healthDetails: HealthDetails) {
        for healthDetail in HealthDetail.allCases {
            guard healthDetails.hasSet(healthDetail),
                  let data = healthDetails.data(for: healthDetail)
            else { continue }
            self[healthDetail] = (healthDetails.date, data)
        }
    }
}
extension Dictionary where Key == HealthDetail, Value == DatedHealthData {
    var datedWeight: DatedWeight? {
        guard let tuple = self[HealthDetail.weight],
              let weight = tuple.data as? HealthDetails.Weight
        else { return nil }
        return .init(date: tuple.date, weight: weight)
    }
    var weight: HealthDetails.Weight? {
        get { datedWeight?.weight }
        set {
            guard let newValue, let datedWeight else {
                self[HealthDetail.weight] = nil
                return
            }
            self[HealthDetail.weight] = (datedWeight.date, newValue)
        }
    }
    
    var datedLeanBodyMass: DatedLeanBodyMass? {
        guard let tuple = self[HealthDetail.leanBodyMass],
              let leanBodyMass = tuple.data as? HealthDetails.LeanBodyMass
        else { return nil }
        return .init(date: tuple.date, leanBodyMass: leanBodyMass)
    }
    var leanBodyMass: HealthDetails.LeanBodyMass? {
        get { datedLeanBodyMass?.leanBodyMass }
        set {
            guard let newValue, let datedLeanBodyMass else {
                self[HealthDetail.leanBodyMass] = nil
                return
            }
            self[HealthDetail.leanBodyMass] = (datedLeanBodyMass.date, newValue)
        }
    }
    
    var datedPregnancyStatus: DatedPregnancyStatus? {
        guard let tuple = self[HealthDetail.preganancyStatus],
              let pregnancyStatus = tuple.data as? PregnancyStatus
        else { return nil }
        return .init(date: tuple.date, pregnancyStatus: pregnancyStatus)
    }
    var pregnancyStatus: PregnancyStatus? {
        get { datedPregnancyStatus?.pregnancyStatus }
        set {
            guard let newValue, let datedPregnancyStatus else {
                self[HealthDetail.preganancyStatus] = nil
                return
            }
            self[HealthDetail.preganancyStatus] = (datedPregnancyStatus.date, newValue)
        }
    }
    
    var datedHeight: DatedHeight? {
        guard let tuple = self[HealthDetail.height],
              let height = tuple.data as? HealthDetails.Height
        else { return nil }
        return .init(date: tuple.date, height: height)
    }
    var height: HealthDetails.Height? {
        get { datedHeight?.height }
        set {
            guard let newValue, let datedHeight else {
                self[HealthDetail.height] = nil
                return
            }
            self[HealthDetail.height] = (datedHeight.date, newValue)
        }
    }
    
    var datedFatPercentage: DatedFatPercentage? {
        guard let tuple = self[HealthDetail.fatPercentage],
              let fatPercentage = tuple.data as? HealthDetails.FatPercentage
        else { return nil }
        return .init(date: tuple.date, fatPercentage: fatPercentage)
    }
    var fatPercentage: HealthDetails.FatPercentage? {
        get { datedFatPercentage?.fatPercentage }
        set {
            guard let newValue, let datedFatPercentage else {
                self[HealthDetail.fatPercentage] = nil
                return
            }
            self[HealthDetail.fatPercentage] = (datedFatPercentage.date, newValue)
        }
    }
    var maintenance: HealthDetails.Maintenance? {
        self[HealthDetail.maintenance]?.data as? HealthDetails.Maintenance
    }
    
    var dateOfBirthComponents: DateComponents? {
        self[HealthDetail.age]?.data as? DateComponents
    }
    
    var biologicalSex: BiologicalSex? {
        self[HealthDetail.biologicalSex]?.data as? BiologicalSex
    }
    
    var smokingStatus: SmokingStatus? {
        self[HealthDetail.smokingStatus]?.data as? SmokingStatus
    }
}
