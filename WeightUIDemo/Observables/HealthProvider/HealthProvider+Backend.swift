import Foundation

//TODO: Replace these with actual backend manipulation in Prep

extension HealthProvider {
    
    //TODO: Make sure that the start date gets the first date that actually has food logged in it so that we don't get a Day we may have created to house something like a legacy height measurement.
    static func fetchBackendLogStartDate() async -> Date {
        LogStartDate
    }

    static func fetchBackendDaysStartDate() async -> Date {
        DaysStartDate
    }

    func setBackendDietaryEnergyPoint(_ point: DietaryEnergyPoint, for date: Date) {
        Task {
            var day = await fetchOrCreateDayFromDocuments(date)
            day.dietaryEnergyPoint = point
            await saveDayInDocuments(day)
        }
    }

    func fetchOrCreateBackendWeight(for date: Date) async -> HealthDetails.Weight {
        let healthDetails = await fetchOrCreateHealthDetailsFromDocuments(date)
        return healthDetails.weight
    }
    func fetchBackendDietaryEnergyPoint(for date: Date) async -> DietaryEnergyPoint? {
        let day = await fetchOrCreateDayFromDocuments(date)
        return day.dietaryEnergyPoint
    }
    
    func fetchBackendEnergyInKcal(for date: Date) async -> Double? {
        let day = await fetchOrCreateDayFromDocuments(date)
        return day.energyInKcal
    }    
}

extension HealthProvider {
    
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
                        source: .notCounted
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

                /// If its using a movingAverage, for each of the `numberOfDays` of the interval
                if let movingAverage = point.movingAverage {
                    let interval = movingAverage.interval
                    var points: [WeightChangePoint.MovingAverage.Point] = []

                    for index in 0..<interval.numberOfDays {

                        /// Compute the date
                        let date = point.date.moveDayBy(-index)

                        /// Try and fetch the `HealthDetails.Weight?` from the backend for the computed date
                        let weight = await fetchOrCreateBackendWeight(for: date)

                        /// If we get it, then create a `WeightChangePoint.MovingAverage.Point` with it and append it to the array. If we don't have it, then create the point with a nil `weight` and still append it.
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
                    let weight = await fetchOrCreateBackendWeight(for: point.date)
                    /// Set this weight's `weightInKg` value as the `kg` value
                    point.kg = weight.weightInKg
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
}

//func latestHealthDetails(to date: Date = Date.now) -> HealthProvider.LatestHealthDetails {
//    let start = CFAbsoluteTimeGetCurrent()
//    var latest = HealthProvider.LatestHealthDetails()
//    
//    /// We use `DaysStartDate` here, which could be before `LogStartDate` because we might have fetched temporal values (height, weight, lean body mass, fat percentage or dietary energy) for dates before the `LogStartDate` to get an initial value
//    let numberOfDays = Date.now.numberOfDaysFrom(DaysStartDate)
//    var retrievedDetails: [HealthDetail] = []
//    for i in 1...numberOfDays {
//        let date = Date.now.moveDayBy(-i)
//        guard let healthDetails = fetchHealthDetailsFromDocuments(date) else {
//            continue
//        }
//
//        if healthDetails.hasSet(.weight) {
//            latest.weight = .init(date: date, weight: healthDetails.weight)
//            retrievedDetails.append(.weight)
//        }
//
//        if healthDetails.hasSet(.height) {
//            latest.height = .init(date: date, height: healthDetails.height)
//            retrievedDetails.append(.height)
//        }
//
//        if healthDetails.hasSet(.leanBodyMass) {
//            latest.leanBodyMass = .init(date: date, leanBodyMass: healthDetails.leanBodyMass)
//            retrievedDetails.append(.leanBodyMass)
//        }
//        
//        if healthDetails.hasSet(.preganancyStatus) {
//            latest.pregnancyStatus = .init(date: date, pregnancyStatus: healthDetails.pregnancyStatus)
//        }
//        
//        if healthDetails.hasSet(.maintenance) {
//            latest.maintenance = .init(date: date, maintenance: healthDetails.maintenance)
//        }
//
//        /// Once we get all (temporal) HealthDetails, stop searching
//        if retrievedDetails.containsAllTemporalCases {
//            break
//        }
//    }
//    
//    print("Getting latestHealthDetails for \(numberOfDays) numberOfDays took: \(CFAbsoluteTimeGetCurrent()-start)s")
//    return latest
//}


extension HealthProvider {
    //TODO: To be replaced in Prep with a function that asks backend for the earliest Days that contain age, sex, or smokingStatus to be as optimized as possible
    func bringForwardNonTemporalHealthDetails() async {
        guard !healthDetails.missingNonTemporalHealthDetails.isEmpty else { return }
        let start = CFAbsoluteTimeGetCurrent()
        
        /// We use the `LogStartDate` here because non-temporal details wouldn't be set for days before that (it's only set in the case of temporal details like height, weight, fat, dietary energy, fat percentage—when the earliest available value in HealthKit for any of those is on a date before the log start date.
        let numberOfDays = healthDetails.date.numberOfDaysFrom(LogStartDate)
        guard numberOfDays >= 0 else { return }
        for i in 0...numberOfDays {
            let date = healthDetails.date.moveDayBy(-i)
            guard let pastHealthDetails = await fetchHealthDetailsFromDocuments(date) else {
                continue
            }

            if !healthDetails.hasSet(.age), let dateOfBirthComponents = pastHealthDetails.dateOfBirthComponents {
                healthDetails.dateOfBirthComponents = dateOfBirthComponents
            }
            
            if !healthDetails.hasSet(.sex), pastHealthDetails.hasSet(.sex) {
                healthDetails.biologicalSex = pastHealthDetails.biologicalSex
            }
            
            if !healthDetails.hasSet(.smokingStatus), pastHealthDetails.hasSet(.smokingStatus) {
                healthDetails.smokingStatus = pastHealthDetails.smokingStatus
            }

            /// Once we get all non-temporal HealthDetails, stop searching early
            if healthDetails.missingNonTemporalHealthDetails.isEmpty {
                break
            }
        }
        
        print("bringForwardNonTemporalHealthDetails() for \(numberOfDays) numberOfDays took: \(CFAbsoluteTimeGetCurrent()-start)s")
    }
}
