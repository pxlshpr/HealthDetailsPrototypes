import HealthKit
import PrepShared

struct HealthKitEnergyRequest {
    let energyType: EnergyType
    let energyUnit: EnergyUnit
    let interval: HealthInterval
    let date: Date
    
    init(
        _ energyType: EnergyType,
        _ energyUnit: EnergyUnit,
        _ interval: HealthInterval,
        _ date: Date
    ) {
        self.energyType = energyType
        self.energyUnit = energyUnit
        self.interval = interval
        self.date = date
    }
}

extension HealthKitEnergyRequest {
    var intervalType: HealthIntervalType { interval.intervalType }
    var typeIdentifier: HKQuantityTypeIdentifier { energyType.hkQuantityTypeIdentifier }
    var hkQuantityType: HKQuantityType { HKQuantityType(typeIdentifier)}
    var unit: HKUnit { energyUnit.healthKitUnit }
    
//    func requestPersmissions() async throws {
//        try await HealthStore.requestPermissions(quantityTypeIdentifiers: [typeIdentifier])
//    }
    
    var startDate: Date { interval.startDate(with: date) }
    var dateRange: ClosedRange<Date> { interval.dateRange(with: date) }
}


extension HealthKitEnergyRequest {

    func dailyAverage() async -> Double {
        let statisticsCollection = await HealthStore.dailyStatistics(
            for: typeIdentifier,
            from: startDate,
            to: date
        )
        return await dailyAverage(using: statisticsCollection)
    }
    
    func dailyAverage(using statisticsCollection: HKStatisticsCollection) async -> Double {
        
        var sumQuantities: [Date: HKQuantity] = [:]
        for day in dateRange.days {
            guard let statistics = statisticsCollection.statistics(for: day) else {
//                throw HealthStoreError.couldNotGetStatistics
                return 0
            }
            guard let sumQuantity = statistics.sumQuantity() else {
                continue
            }
            sumQuantities[day] = sumQuantity
        }
        
        guard !sumQuantities.isEmpty else {
            /// This indicates that there is no data—or permissions haven't been granted
            return 0
//            return nil
        }
        
        let sum = sumQuantities
            .values
            .map {
                $0.doubleValue(for: unit)
                    .rounded(.towardZero) /// Use Health App's rounding (towards zero)
            }
            .reduce(0, +)
        
        /// Average by the number of `sumQuantities`, to filter out days that may not have been logged (by not wearing the Apple Watch, for instance)—which would otherwise skew the results to be lower.
        return sum / Double(sumQuantities.count)
    }
}
