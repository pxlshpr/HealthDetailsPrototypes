import Foundation
import PrepShared

public struct Settings: Codable, Hashable {
    
    public var energyUnit: EnergyUnit = .kcal
    public var bodyMassUnit: BodyMassUnit = .kg
    public var heightUnit: HeightUnit = .cm
    public var volumeUnits: VolumeUnits = .defaultUnits
    
    public var macrosBarType: MacrosBarType = .foodItem
    
    public var nutrientsFilter: NutrientsFilter = .all
    public var showRDAGoals: Bool = true
    public var expandedMicroGroups: [MicroGroup] = []
    public var metricType: GoalMetricType = .consumed
    
    public var displayedMicros: [Micro] = []
    
    /// Removed because these should be per-day, similar to `Plan` and `HealthDetails`
//    public var dailyValues: [Micro: DailyValue] = [:]
}

public extension Settings {

    var asData: Data {
        try! JSONEncoder().encode(self)
    }
}
