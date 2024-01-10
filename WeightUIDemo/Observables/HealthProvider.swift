import SwiftUI

@Observable class HealthProvider {
    
    let isCurrent: Bool
    var healthDetails: HealthDetails
    
    var latest: LatestHealthDetails
    
    var currentOrLatestWeightInKg: Double? {
        healthDetails.weight.weightInKg ?? latest.weight?.weight.weightInKg
    }
    
    var currentOrLatestMaintenanceInKcal: Double? {
        healthDetails.maintenance.kcal ?? latest.maintenance?.maintenance.kcal
    }
    
    var currentOrLatestLeanBodyMassInKg: Double? {
        healthDetails.leanBodyMass.leanBodyMassInKg ?? latest.leanBodyMass?.leanBodyMass.leanBodyMassInKg
    }
    
    var currentOrLatestHeightInCm: Double? {
        healthDetails.height.heightInCm ?? latest.height?.height.heightInCm
    }
    
    var biologicalSex: BiologicalSex {
        healthDetails.biologicalSex
    }
    
    var ageInYears: Int? {
        healthDetails.ageInYears
    }
    
    struct LatestHealthDetails {
        var weight: Weight?
        var height: Height?
        var leanBodyMass: LeanBodyMass?
        var maintenance: Maintenance?
        var pregnancyStatus: PregnancyStatus?
        
        struct LeanBodyMass {
            let date: Date
            var leanBodyMass: HealthDetails.LeanBodyMass
        }
        
        struct Weight {
            let date: Date
            var weight: HealthDetails.Weight
        }
        
        struct Height {
            let date: Date
            var height: HealthDetails.Height
        }
        
        struct Maintenance {
            let date: Date
            var maintenance: HealthDetails.Maintenance
        }
        
        struct PregnancyStatus {
            let date: Date
            var pregnancyStatus: WeightUIDemo.PregnancyStatus
        }
    }
    
    init(
        isCurrent: Bool,
        healthDetails: HealthDetails,
        latest: LatestHealthDetails = LatestHealthDetails()
    ) {
        self.isCurrent = isCurrent
        self.healthDetails = healthDetails
        self.latest = latest
        Task {
            await self.update()
        }
    }
}

extension HealthProvider {
    
//    func fillInMissingAdaptivePoints() {
//        let initial = self.healthDetails
//        healthDetails.maintenance.adaptive.fillInMissingPoints(date: healthDetails.date)
//        if self.healthDetails != initial {
//            save()
//        }
//    }
    
    func update() async {
        /// [ ] This needs to be an async func that gets called soon after init (and later, like when scenePhase changes etc)
        /// [ ] Now for each point, evaluate it if needed (which grabs the current log value, healthKit value)
        /// [ ] Now once that's done, calculate the average of all the non-average types and set those to the average types
        /// [ ] Now calculate the kcalPerDay
        await fetchBackendData()
//        await fetchHealthKitData()
//        await recalculate()
    }
    
    func fetchHealthKitData() async {
        /// [ ] DietaryEnergy
        let points = healthDetails.maintenance.adaptive.dietaryEnergy.points
        for index in points.indices {
            guard points[index].source == .healthKit else { continue }
            
        }
    }

    func fetchBackendData() async {
        /// DietaryEnergy
        var points: [DietaryEnergyPoint] = []
        let numberOfDays = healthDetails.maintenance.adaptive.interval.numberOfDays
        for index in 0..<numberOfDays {
            let date = healthDetails.date.moveDayBy(-(index + 1))

            if let point = fetchBackendDietaryEnergyPoint(for: date) {
                points.append(point)
            } else if let energyInKcal = fetchBackendEnergyInKcal(for: date) {
                let point = DietaryEnergyPoint(
                    date: date,
                    kcal: energyInKcal,
                    source: .log
                )
                points.append(point)
                setBackendDietaryEnergyPoint(point, for: date)
            } else {
                let point = DietaryEnergyPoint(
                    date: date,
                    source: .useAverage
                )
                points.append(point)
                setBackendDietaryEnergyPoint(point, for: date)
            }
        }
        print("Setting \(points.count) dietaryEnergyPoints")
        healthDetails.maintenance.adaptive.dietaryEnergy.points = points
        save()

        /// [ ] Weight
    }

    func recalculate() async {
        
    }
}

//extension HealthDetails.Maintenance.Adaptive {
//    var numberOfDays: Int { interval.numberOfDays }
//    
//    mutating func fillInMissingPoints(date: Date) {
//        dietaryEnergy.fillInMissingPoints(numberOfDays: numberOfDays, date: date)
//        weightChange.fillInMissingPoints(date: date)
//    }
//}
//
//extension HealthDetails.Maintenance.Adaptive.WeightChange {
//    mutating func fillInMissingPoints(date: Date) {
//    }
//}
//
//extension HealthDetails.Maintenance.Adaptive.DietaryEnergy {
//    mutating func fillInMissingPoints(numberOfDays: Int, date: Date) {
//        var points: [DietaryEnergyPoint] = []
//        for index in 0..<numberOfDays {
//            /// If a point already exists at this index, grab it, otherwise create one with `.log` type
//            if index < self.points.count {
//                points.append(self.points[index])
//            } else {
//                let date = date.moveDayBy(-(index + 1))
//                points.append(.init(date: date, type: .log))
//            }
//        }
//        self.points = points
//    }
//}

extension HealthDetails {
    
    var missingNonTemporalHealthDetails: [HealthDetail] {
        HealthDetail.allNonTemporalHealthDetails.filter { !hasSet($0) }
    }

    func hasSet(_ healthDetail: HealthDetail) -> Bool {
        switch healthDetail {
        case .maintenance:
            maintenance.kcal != nil
        case .age:
            ageInYears != nil
        case .sex:
            biologicalSex != .notSet
        case .weight:
            weight.weightInKg != nil
        case .leanBodyMass:
            leanBodyMass.leanBodyMassInKg != nil
        case .height:
            height.heightInCm != nil
        case .preganancyStatus:
            pregnancyStatus != .notSet
        case .smokingStatus:
            smokingStatus != .notSet
        }
    }

    func secondaryValueString(
        for healthDetail: HealthDetail,
        _ settingsProvider: SettingsProvider
    ) -> String? {
        switch healthDetail {
        case .leanBodyMass:
            leanBodyMass.secondaryValueString()
        default:
            nil
        }
    }
    func valueString(
        for healthDetail: HealthDetail,
        _ settingsProvider: SettingsProvider
    ) -> String {
        switch healthDetail {
        case .age:
            if let ageInYears {
                "\(ageInYears)"
            } else {
                "Not Set"
            }
        case .sex:
            biologicalSex.name
        case .weight:
            weight.valueString(in: settingsProvider.bodyMassUnit)
        case .leanBodyMass:
            leanBodyMass.valueString(in: settingsProvider.bodyMassUnit)
        case .height:
            height.valueString(in: settingsProvider.heightUnit)
        case .preganancyStatus:
            pregnancyStatus.name
        case .smokingStatus:
            smokingStatus.name
        case .maintenance:
            maintenance.valueString(in: settingsProvider.energyUnit)
        }
    }
}

//TODO: For each of these:
/// [ ] Recalculate any HealthDetails like calculated LBM, Resting Energy
/// [ ] This could affect plans so make sure this occurs
/// [ ] Send a notification so that DailyValues set on this day get updated too if dependent on the HealthDetail

extension HealthProvider {

    func saveMaintenance(_ maintenance: HealthDetails.Maintenance) {
        healthDetails.maintenance = maintenance
        save()
    }

    func saveRestingEnergy(_ restingEnergy: HealthDetails.Maintenance.Estimate.RestingEnergy) {
        healthDetails.maintenance.estimate.restingEnergy = restingEnergy
        save()
    }

    func saveEstimate(_ estimate: HealthDetails.Maintenance.Estimate) {
        healthDetails.maintenance.estimate = estimate
        save()
    }

    func saveActiveEnergy(_ activeEnergy: HealthDetails.Maintenance.Estimate.ActiveEnergy) {
        healthDetails.maintenance.estimate.activeEnergy = activeEnergy
        save()
    }

    func savePregnancyStatus(_ pregnancyStatus: PregnancyStatus) {
        healthDetails.pregnancyStatus = pregnancyStatus
        save()
    }
    
    func saveBiologicalSex(_ sex: BiologicalSex) {
        healthDetails.biologicalSex = sex
        save()
    }
    
    func saveDateOfBirth(_ date: Date?) {
        healthDetails.dateOfBirth = date
        save()
    }

    func saveSmokingStatus(_ smokingStatus: SmokingStatus) {
        healthDetails.smokingStatus = smokingStatus
        save()
    }
    
    //TODO: Sync stuff
    /// [ ] Handle sync being turned on and off for these here
    func saveHeight(_ height: HealthDetails.Height) {
        healthDetails.height = height
        save()
    }
    
    func saveWeight(_ weight: HealthDetails.Weight) {
        healthDetails.weight = weight
        save()
    }
    
    func saveLeanBodyMass(_ leanBodyMass: HealthDetails.LeanBodyMass) {
        healthDetails.leanBodyMass = leanBodyMass
        save()
    }
    
    //TODO: Persist changes
    /// [ ] Replace Mock coding with actual persistence
    func updateLatestWeight(_ weight: HealthDetails.Weight) {
        guard let latestWeight = latest.weight else { return }
        latest.weight?.weight = weight
        
        var healthDetails = fetchHealthDetailsFromDocuments(latestWeight.date)
        healthDetails.weight = weight
        saveHealthDetailsInDocuments(healthDetails)
    }
    
    func updateLatestHeight(_ height: HealthDetails.Height) {
        guard let latestHeight = latest.height else { return }
        latest.height?.height = height
        
        var healthDetails = fetchHealthDetailsFromDocuments(latestHeight.date)
        healthDetails.height = height
        saveHealthDetailsInDocuments(healthDetails)
    }

    func updateLatestMaintenance(_ maintenance: HealthDetails.Maintenance) {
        guard let latestMaintenance = latest.maintenance else { return }
        latest.maintenance?.maintenance = maintenance
        
        var healthDetails = fetchHealthDetailsFromDocuments(latestMaintenance.date)
        healthDetails.maintenance = maintenance
        saveHealthDetailsInDocuments(healthDetails)
    }

    func updateLatestPregnancyStatus(_ pregnancyStatus: PregnancyStatus) {
        guard let latestPregnancyStatus = latest.pregnancyStatus else { return }
        latest.pregnancyStatus?.pregnancyStatus = pregnancyStatus
        
        var healthDetails = fetchHealthDetailsFromDocuments(latestPregnancyStatus.date)
        healthDetails.pregnancyStatus = pregnancyStatus
        saveHealthDetailsInDocuments(healthDetails)
    }

    func updateLatestLeanBodyMass(_ leanBodyMass: HealthDetails.LeanBodyMass) {
        guard let latestLeanBodyMass = latest.leanBodyMass else { return }
        latest.leanBodyMass?.leanBodyMass = leanBodyMass
        
        var healthDetails = fetchHealthDetailsFromDocuments(latestLeanBodyMass.date)
        healthDetails.leanBodyMass = leanBodyMass
        saveHealthDetailsInDocuments(healthDetails)
    }

}

//TODO: Replace these with actual backend manipulation in Prep

extension HealthProvider {
    func setBackendDietaryEnergyPoint(_ point: DietaryEnergyPoint, for date: Date) {
        var day = fetchDayFromDocuments(date)
        day.dietaryEnergyPoint = point
        saveDayInDocuments(day)
    }
    func fetchBackendDietaryEnergyPoint(for date: Date) -> DietaryEnergyPoint? {
        let day = fetchDayFromDocuments(date)
        return day.dietaryEnergyPoint
    }
    
    func fetchBackendEnergyInKcal(for date: Date) -> Double? {
        let day = fetchDayFromDocuments(date)
        return day.energyInKcal
    }
    
    func save() {
        saveHealthDetailsInDocuments(healthDetails)
    }
}

#Preview("Demo") {
    DemoView()
}
