import Foundation
import PrepShared

struct Settings: Codable, Hashable {
    
    var energyUnit: EnergyUnit = .kcal
    var bodyMassUnit: BodyMassUnit = .kg
    var heightUnit: HeightUnit = .cm
    var volumeUnits: VolumeUnits = .defaultUnits
    
    var macrosBarType: MacrosBarType = .foodItem
    
    var nutrientsFilter: NutrientsFilter = .all
    var showRDAGoals: Bool = true
    var expandedMicroGroups: [MicroGroup] = []
    var metricType: GoalMetricType = .consumed
    
    var displayedMicros: [Micro] = []
    
    var healthKitSyncedHealthDetails: [HealthDetail] = []
    var dailyValueTypes: [HealthDetail : DailyValueType] = [:]
    
    /// Removed because these should be per-day, similar to `Plan` and `HealthDetails`
//    public var dailyValues: [Micro: DailyValue] = [:]
}

extension Settings {

    mutating func setDailyValueType(_ type: DailyValueType, for healthDetail: HealthDetail) {
        dailyValueTypes[healthDetail] = type
    }

    func dailyValueType(for healthDetail: HealthDetail) -> DailyValueType {
        dailyValueTypes[healthDetail] ?? .last
    }

    func dailyValueType(forHealthKitType type: HealthKitType) -> DailyValueType? {
        guard let healthDetail = type.healthDetail else { return nil }
        return dailyValueType(for: healthDetail)
    }

    func isHealthKitSyncing(_ healthDetail: HealthDetail) -> Bool {
        healthKitSyncedHealthDetails.contains(healthDetail)
    }
    
    mutating func setHealthKitSyncing(for healthDetail: HealthDetail, to isOn: Bool) {
        switch isOn {
        case true:
            guard !isHealthKitSyncing(healthDetail) else { return }
            healthKitSyncedHealthDetails.append(healthDetail)
        case false:
            healthKitSyncedHealthDetails.removeAll(where: { $0 == healthDetail })
        }
    }

    var asData: Data {
        try! JSONEncoder().encode(self)
    }
}
