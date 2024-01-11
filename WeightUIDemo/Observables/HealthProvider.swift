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
        await fetchHealthKitData()
        await recalculate()
    }
    
    func fetchHealthKitData() async {
        /// [ ] DietaryEnergy
        let points = healthDetails.maintenance.adaptive.dietaryEnergy.points
        for index in points.indices {
            guard points[index].source == .healthKit else { continue }
            
        }
    }

    func fetchBackendData() async {
        
        func fetchDietaryEnergyData() async {
            let numberOfDays = healthDetails.maintenance.adaptive.interval.numberOfDays
            var points: [DietaryEnergyPoint] = []
            for index in 0..<numberOfDays {
                let date = healthDetails.date.moveDayBy(-(index + 1))
                
                if let point = await fetchBackendDietaryEnergyPoint(for: date) {
                    points.append(point)
                } else if let energyInKcal = await fetchBackendEnergyInKcal(for: date) {
                    /// Create a `.log` sourced `DietaryEnergyPoint` for this date
                    let point = DietaryEnergyPoint(
                        date: date,
                        kcal: energyInKcal,
                        source: .log
                    )
                    points.append(point)

                    /// Set this in the backend
                    setBackendDietaryEnergyPoint(point, for: date)
                } else {
                    /// Fallback to creating an exclusionary `DietaryEnergyPoint` for this date
                    let point = DietaryEnergyPoint(
                        date: date,
                        source: .useAverage
                    )
                    points.append(point)

                    /// Set this in the backend
                    setBackendDietaryEnergyPoint(point, for: date)
                }
            }
            healthDetails.maintenance.adaptive.dietaryEnergy = .init(points: points)
        }
        
        func fetchWeightChangeData() async {
            var weightChange: WeightChange {
                get { healthDetails.maintenance.adaptive.weightChange }
                set { healthDetails.maintenance.adaptive.weightChange = newValue }
            }
            guard weightChange.type == .usingPoints else { return }
            
            /// As a sanity check, if `points` is nil, set it
            let emptyPoints = WeightChange.Points(
                date: healthDetails.date,
                interval: healthDetails.maintenance.adaptive.interval
            )
            if weightChange.points == nil {
                weightChange.points = emptyPoints
            }
            
            var start: WeightChangePoint {
                get { weightChange.points?.start ?? emptyPoints.start }
                set { weightChange.points?.start = newValue }
            }

            var end: WeightChangePoint {
                get { weightChange.points?.end ?? emptyPoints.end }
                set { weightChange.points?.end = newValue }
            }

            /// For each of `points.start` and `points.end`, do the following
            func fetchData(for point: inout WeightChangePoint) async {
                if let movingAverage = point.movingAverage {
                    let interval = movingAverage.interval
                    var points: [WeightChangePoint.MovingAverage.Point] = []
                    /// If its using a movingAverage, for each of the `numberOfDays` of the interval
                    for index in 0..<interval.numberOfDays {
                        /// Compute the date
                        let date = healthDetails.date.moveDayBy(-index)
                        /// Try and fetch the `HealthDetails.Weight?` from the backend for the computed date
                        let weight = await fetchBackendWeight(for: date)
                        /// If we get it, then create a `WeightChangePoint.MovingAverage.Point` with it and append it to the array
                        /// If we don't have it, then create the point with a nil `weight` and still append it
                        let point = WeightChangePoint.MovingAverage.Point(date: date, weight: weight)
                        points.append(point)
                    }
                    /// Once completed, calculate the average and set it in `kg`
                    let average = points.average
                    point.kg = average
                    point.movingAverage = .init(
                        interval: interval,
                        points: points
                    )
                    point.weight = nil
                } else {
                    /// If its not using a movingAverage, fetch the `HealthDetails.Weight?` from the backend for the date
                    let weight = await fetchBackendWeight(for: point.date)
                    /// Set this weight's `weightInKg` value as the `kg` value
                    point.kg = weight?.weightInKg
                    point.weight = weight
                }
            }
            
            await fetchData(for: &start)
            await fetchData(for: &end)

            /// Once completed, calculate the weightDelta if possible
            weightChange.kg = if let end = end.kg, let start = start.kg {
                end - start
            } else {
                nil
            }
        }
        
        await fetchDietaryEnergyData()
        await fetchWeightChangeData()
        save()
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
//extension WeightChange {
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
    
    func saveDietaryEnergyPoint(_ point: DietaryEnergyPoint) {
        var day = fetchDayFromDocuments(point.date)
        day.dietaryEnergyPoint = point
        //TODO: Get any other HealthDetails (other than the one in this HealthProvider) that uses this point and get them to update within an instantiated HealthProvider as well
        saveDayInDocuments(day)
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

    func fetchBackendWeight(for date: Date) async -> HealthDetails.Weight? {
        let healthDetails = fetchHealthDetailsFromDocuments(date)
        return healthDetails.weight
    }
    func fetchBackendDietaryEnergyPoint(for date: Date) async -> DietaryEnergyPoint? {
        let day = fetchDayFromDocuments(date)
        return day.dietaryEnergyPoint
    }
    
    func fetchBackendEnergyInKcal(for date: Date) async -> Double? {
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
