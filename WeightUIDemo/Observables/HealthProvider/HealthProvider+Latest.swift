import Foundation

extension HealthProvider {
    func setLatest(_ latest: [HealthDetail : DatedHealthData]) {
        self.latest = latest
        healthDetails.bringForwardNonTemporalHealthDetails(from: latest)
    }
}
extension HealthDetails {
    
    mutating func bringForwardNonTemporalHealthDetails(from latest: [HealthDetail : DatedHealthData] ) {
        if !hasSet(.age), let components = latest.dateOfBirthComponents {
            self.dateOfBirthComponents = components
        }
        if !hasSet(.sex), let biologicalSex = latest.biologicalSex {
            self.biologicalSex = biologicalSex
        }
        if !hasSet(.smokingStatus), let smokingStatus = latest.smokingStatus {
            self.smokingStatus = smokingStatus
        }
    }

    func populateLatestDict(_ dict: inout [HealthDetail : DatedHealthData]) {
        for healthDetail in HealthDetail.allCases {
            guard !dict.keys.contains(healthDetail),
                  hasSet(healthDetail),
                  let data = data(for: healthDetail)
            else { continue }
            dict[healthDetail] = (date, data)
        }
    }
}

typealias DatedHealthData = (date: Date, data: Any)

extension Dictionary where Key == HealthDetail, Value == DatedHealthData {
    var weightWithDate: (date: Date, weight: HealthDetails.Weight)? {
        guard let tuple = self[HealthDetail.weight],
              let weight = tuple.data as? HealthDetails.Weight
        else { return nil }
        return (tuple.date, weight)
    }
    var weight: HealthDetails.Weight? {
        get { weightWithDate?.weight }
        set {
            guard let newValue, let weightWithDate else {
                self[HealthDetail.weight] = nil
                return
            }
            self[HealthDetail.weight] = (weightWithDate.date, newValue)
        }
    }
    
    var leanBodyMassWithDate: (date: Date, leanBodyMass: HealthDetails.LeanBodyMass)? {
        guard let tuple = self[HealthDetail.leanBodyMass],
              let leanBodyMass = tuple.data as? HealthDetails.LeanBodyMass
        else { return nil }
        return (tuple.date, leanBodyMass)
    }
    var leanBodyMass: HealthDetails.LeanBodyMass? {
        get { leanBodyMassWithDate?.leanBodyMass }
        set {
            guard let newValue, let leanBodyMassWithDate else {
                self[HealthDetail.leanBodyMass] = nil
                return
            }
            self[HealthDetail.leanBodyMass] = (leanBodyMassWithDate.date, newValue)
        }
    }
    
    var maintenanceWithDate: (date: Date, maintenance: HealthDetails.Maintenance)? {
        guard let tuple = self[HealthDetail.maintenance],
              let maintenance = tuple.data as? HealthDetails.Maintenance
        else { return nil }
        return (tuple.date, maintenance)
    }
    var maintenance: HealthDetails.Maintenance? {
        get { maintenanceWithDate?.maintenance }
        set {
            guard let newValue, let maintenanceWithDate else {
                self[HealthDetail.maintenance] = nil
                return
            }
            self[HealthDetail.maintenance] = (maintenanceWithDate.date, newValue)
        }
    }
    
    var pregnancyStatusWithDate: (date: Date, pregnancyStatus: PregnancyStatus)? {
        guard let tuple = self[HealthDetail.preganancyStatus],
              let status = tuple.data as? PregnancyStatus
        else { return nil }
        return (tuple.date, status)
    }
    var pregnancyStatus: PregnancyStatus? {
        get { pregnancyStatusWithDate?.pregnancyStatus }
        set {
            guard let newValue, let pregnancyStatusWithDate else {
                self[HealthDetail.preganancyStatus] = nil
                return
            }
            self[HealthDetail.preganancyStatus] = (pregnancyStatusWithDate.date, newValue)
        }
    }
    
    var heightWithDate: (date: Date, height: HealthDetails.Height)? {
        guard let tuple = self[HealthDetail.height],
              let height = tuple.data as? HealthDetails.Height
        else { return nil }
        return (tuple.date, height)
    }
    var height: HealthDetails.Height? {
        get { heightWithDate?.height }
        set {
            guard let newValue, let heightWithDate else {
                self[HealthDetail.height] = nil
                return
            }
            self[HealthDetail.height] = (heightWithDate.date, newValue)
        }
    }
    
    var dateOfBirthComponents: DateComponents? {
        self[HealthDetail.age]?.data as? DateComponents
    }
    
    var biologicalSex: BiologicalSex? {
        self[HealthDetail.sex]?.data as? BiologicalSex
    }
    
    var smokingStatus: SmokingStatus? {
        self[HealthDetail.smokingStatus]?.data as? SmokingStatus
    }
}
