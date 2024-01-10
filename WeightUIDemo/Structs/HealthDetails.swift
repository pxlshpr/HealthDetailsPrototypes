import Foundation
import PrepShared

struct HealthDetails: Hashable, Codable {
 
    let date: Date
    var biologicalSex: BiologicalSex = .notSet
    var dateOfBirthComponents: DateComponents?
    var smokingStatus: SmokingStatus = .notSet
    var pregnancyStatus: PregnancyStatus = .notSet
    var height = Height()
    var weight = Weight()
    var leanBodyMass = LeanBodyMass()
    var maintenance = Maintenance()
}

//MARK: - Maintenance

struct DietaryEnergyPoint: Hashable, Codable {
    var date: Date
    var kcal: Double?
    var source: DietaryEnergyPointSource
}

extension Array where Element == DietaryEnergyPoint {
    mutating func fillAverages() {
        guard let averageOfPointsNotUsingAverage else { return }
        for i in 0..<count {
            /// Only fill with average if there is no value for it or it already has a type of `average`
            guard self[i].source == .useAverage else { continue }
            self[i].kcal = averageOfPointsNotUsingAverage
        }
    }
    
    var averageOfPointsNotUsingAverage: Double? {
        let values = self
            .filter { $0.source != .useAverage }
            .compactMap { $0.kcal }
        guard !values.isEmpty else { return nil }
        let sum = values.reduce(0) { $0 + $1 }
        return Double(sum) / Double(values.count)
    }
    
    var average: Double? {
        let values = self
            .compactMap { $0.kcal }
        guard !values.isEmpty else { return nil }
        let sum = values.reduce(0) { $0 + $1 }
        return Double(sum) / Double(values.count)
    }
}

extension HealthDetails {
    struct Maintenance: Hashable, Codable {
        
        var type: MaintenanceType = .estimated
        var kcal: Double?
        var adaptive = Adaptive()
        var estimate = Estimate()
        var useEstimateAsFallback: Bool = true
        
        struct Adaptive: Hashable, Codable {
            var kcal: Double? = nil
            var interval: HealthInterval = .init(1, .week)
            
            var dietaryEnergy = DietaryEnergy()
            var weightChange = WeightChange()
            
            struct DietaryEnergy: Hashable, Codable {
                var kcalPerDay: Double?
                var points: [DietaryEnergyPoint] = []
            }
            
            struct WeightChange: Hashable, Codable {
                var kg: Double?
                var isCustom: Bool = false
                var points: [Point] = []

                struct Point: Hashable, Codable {
                    var date: Date
                    var kg: Double?
                    var useMovingAverage: Bool
                    var movingAverageInterval: HealthInterval = .init(7, .day)
                    var weights: [Weight]
                    
                    struct Weight: Hashable, Codable {
                        var date: Date
                        var weight: HealthDetails.Weight
                    }
                }
            }
        }
        
        struct Estimate: Hashable, Codable {
            var kcal: Double?
            var restingEnergy = RestingEnergy()
            var activeEnergy = ActiveEnergy()
            
            struct RestingEnergy: Hashable, Codable {
                var kcal: Double? = nil
                var source: RestingEnergySource = .equation
                
                var equation: RestingEnergyEquation = .katchMcardle
                var healthKitSyncSettings = HealthKitSyncSettings()
            }

            struct ActiveEnergy: Hashable, Codable {
                var kcal: Double? = nil
                var source: ActiveEnergySource = .activityLevel
                
                var activityLevel: ActivityLevel = .lightlyActive
                var healthKitSyncSettings = HealthKitSyncSettings()
            }
            
            struct HealthKitSyncSettings: Hashable, Codable {
                var intervalType: HealthIntervalType = .average
                var interval: HealthInterval = .init(3, .day)
                var correctionValue: CorrectionValue? = nil
                
//                struct Correction: Hashable, Codable {
//                    var type: CorrectionType = .divide
//                    var correction: Double?
//                }
            }

        }

    }
}

//MARK: - LeanBodyMass
extension HealthDetails {
    struct LeanBodyMass: Hashable, Codable {
        var leanBodyMassInKg: Double? = nil
        var fatPercentage: Double? = nil
        var dailyValueType: DailyValueType = .average
        var measurements: [LeanBodyMassMeasurement] = []
        var deletedHealthKitMeasurements: [LeanBodyMassMeasurement] = []
        var isSynced: Bool = false
    }
}

//MARK: - Weight
extension HealthDetails {
    struct Weight: Hashable, Codable {
        var weightInKg: Double? = nil
        var dailyValueType: DailyValueType = .average
        var measurements: [WeightMeasurement] = []
        var deletedHealthKitMeasurements: [WeightMeasurement] = []
        var isSynced: Bool = false
    }
}

extension HealthDetails.Weight {
    func valueString(in unit: BodyMassUnit) -> String {
        weightInKg.valueString(convertedFrom: .kg, to: unit)
    }
}

extension HealthDetails.Maintenance {
    func valueString(in unit: EnergyUnit) -> String {
        kcal.valueString(convertedFrom: .kcal, to: unit)
    }
}

extension HealthDetails.LeanBodyMass {
    func secondaryValueString() -> String? {
        if let fatPercentage {
            "\(fatPercentage.cleanHealth)%"
        } else {
            nil
        }
    }
    func valueString(in unit: BodyMassUnit) -> String {
        leanBodyMassInKg.valueString(convertedFrom: .kg, to: unit)
    }
}

extension HealthDetails.Height {
    func valueString(in unit: HeightUnit) -> String {
        heightInCm.valueString(convertedFrom: .cm, to: unit)
    }
}

extension Double {
    
    func convertEnergy(from fromUnit: EnergyUnit, to toUnit: EnergyUnit) -> Double {
        fromUnit.convert(self, to: toUnit)
//            .rounded(.towardZero)
    }
}
extension Optional where Wrapped == Double {
    
    func convertEnergy(from fromUnit: EnergyUnit, to toUnit: EnergyUnit) -> Double? {
        guard let self else { return nil }
        return fromUnit.convert(self, to: toUnit)
//            .rounded(.towardZero)
    }

    func valueString(convertedFrom fromUnit: EnergyUnit, to unit: EnergyUnit) -> String {
        guard let self else { return "Not Set" }
        let converted = fromUnit.convert(self, to: unit)
        return "\(converted.formattedEnergy) \(unit.doubleUnitString)"
    }
    
    func valueString(convertedFrom fromUnit: BodyMassUnit, to unit: BodyMassUnit) -> String {
        guard let self else { return "Not Set" }
        let converted = fromUnit.convert(self, to: unit)
        let double = unit.doubleComponent(of: converted)
        if let int = unit.intComponent(of: converted), let intUnit = unit.intUnitString {
            return "\(int) \(intUnit) \(double.cleanHealth) \(unit.doubleUnitString)"
        } else {
            return "\(double.cleanHealth) \(unit.doubleUnitString)"
        }
    }
    
    func valueString(convertedFrom fromUnit: HeightUnit, to unit: HeightUnit) -> String {
        guard let self else { return "Not Set" }
        let converted = fromUnit.convert(self, to: unit)
        let double = unit.doubleComponent(of: converted)
        if let int = unit.intComponent(of: converted), let intUnit = unit.intUnitString {
            return "\(int) \(intUnit) \(double.cleanHealth) \(unit.doubleUnitString)"
        } else {
            return "\(double.cleanHealth) \(unit.doubleUnitString)"
        }
    }
}

//MARK: - Height

extension HealthDetails {
    struct Height: Hashable, Codable {
        var heightInCm: Double? = nil
        var measurements: [HeightMeasurement] = []
        var deletedHealthKitMeasurements: [HeightMeasurement] = []
        var isSynced: Bool = false
    }
}


//MARK: - Age

//extension HealthDetails {
//    struct Age: Hashable, Codable {
//        var years: Int?
//        var dateOfBirthComponents: DateComponents?
//        
//        init(years: Int) {
//            self.years = years
//            self.dateOfBirthComponents = years.dateOfBirth.dateComponentsWithoutTime
//        }
//        
//        init(dateOfBirth: Date) {
//            self.years = dateOfBirth.age
//            self.dateOfBirthComponents = dateOfBirth.dateComponentsWithoutTime
//        }
//    }
//}

extension HealthDetails {
    
    var ageInYears: Int? {
        get {
            self.dateOfBirth?.ageInYears
        }
        set {
            guard let newValue else {
                self.dateOfBirthComponents = nil
                return
            }
            self.dateOfBirthComponents = newValue.dateOfBirth.dateComponentsWithoutTime
        }
    }
    
    var dateOfBirth: Date? {
        get {
            guard let dateOfBirthComponents else { return nil }
            var components = dateOfBirthComponents
            components.hour = 0
            components.minute = 0
            components.second = 0
            return Calendar.current.date(from: components)
        }
        set {
            guard let newValue else {
                dateOfBirthComponents = nil
                return
            }
            dateOfBirthComponents = newValue.dateComponentsWithoutTime
        }
    }
}

//MARK: - Measurements

struct HeightMeasurement: Hashable, Identifiable, Codable {
    let id: UUID
    let healthKitUUID: UUID?
    let date: Date
    let heightInCm: Double
    
    init(
        id: UUID = UUID(),
        date: Date,
        heightInCm: Double,
        healthKitUUID: UUID? = nil
    ) {
        self.id = id
        self.healthKitUUID = healthKitUUID
        self.date = date
        self.heightInCm = heightInCm
    }
}

extension HeightMeasurement: Measurable {
    var value: Double {
        heightInCm
    }
}


struct WeightMeasurement: Hashable, Identifiable, Codable {
    let id: UUID
    let healthKitUUID: UUID?
    let date: Date
    let weightInKg: Double
    
    init(
        id: UUID = UUID(),
        date: Date,
        weightInKg: Double,
        healthKitUUID: UUID? = nil
    ) {
        self.id = id
        self.healthKitUUID = healthKitUUID
        self.date = date
        self.weightInKg = weightInKg
    }
}

extension WeightMeasurement: Measurable {
    var value: Double {
        weightInKg
    }
}


struct LeanBodyMassMeasurement: Hashable, Identifiable, Codable {
    let id: UUID
    let source: LeanBodyMassSource
    let date: Date
    let leanBodyMassInKg: Double
    let fatPercentage: Double? /// e.g. 10 for 10%
    
    init(
        id: UUID = UUID(),
        date: Date,
        leanBodyMassInKg: Double,
        fatPercentage: Double? = nil,
        source: LeanBodyMassSource
    ) {
        self.id = id
        self.source = source
        self.date = date
        self.leanBodyMassInKg = leanBodyMassInKg
        self.fatPercentage = fatPercentage
    }
}

extension LeanBodyMassMeasurement: Measurable {
    var healthKitUUID: UUID? {
        source.healthKitUUID
    }
    
    var secondaryValue: Double? {
        fatPercentage?.rounded(toPlaces: 1)
    }
    var secondaryValueUnit: String? {
        "%"
    }
    
    var value: Double {
        leanBodyMassInKg
    }
    
    var imageType: MeasurementImageType {
        switch source {
        case .healthKit:    .healthKit
        default:            .systemImage(source.image, source.imageScale)
        }
    }
}

