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
            guard self[i].source == .notCounted else { continue }
            self[i].kcal = averageOfPointsNotUsingAverage
        }
    }
    
    var averageOfPointsNotUsingAverage: Double? {
        let values = self
            .filter { $0.source != .notCounted }
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

extension Array where Element == WeightChangePoint.MovingAverage.Point {
    var average: Double? {
        let values = self
            .compactMap { $0.weight.weightInKg }
        guard !values.isEmpty else { return nil }
        let sum = values.reduce(0) { $0 + $1 }
        return Double(sum) / Double(values.count)
    }
}

struct WeightChangePoint: Hashable, Codable {
    
    var date: Date
    var kg: Double?
    
    var weight: HealthDetails.Weight?
    var movingAverage: MovingAverage?
    
    var defaultPoints: [MovingAverage.Point] {
        if let points = movingAverage?.points {
            points
        } else if let weight {
            [MovingAverage.Point(date: date, weight: weight)]
        } else {
            []
        }
    }
    
    struct MovingAverage: Hashable, Codable {
        var interval: HealthInterval = .init(7, .day)
        var points: [Point]
        
        struct Point: Hashable, Codable, Identifiable {
            var date: Date
            var weight: HealthDetails.Weight
            
            var id: Date { date }
        }
    }
    
    init(
        date: Date,
        kg: Double? = nil,
        weight: HealthDetails.Weight? = nil,
        movingAverage: MovingAverage? = nil
    ) {
        self.date = date
        self.kg = kg
        self.weight = weight
        self.movingAverage = movingAverage
    }
}

enum WeightChangeType: Int, Hashable, Codable, CaseIterable, Identifiable {
    case usingPoints = 1
    case userEntered
    
    var id: Int { rawValue }
    
    var name: String {
        switch self {
        case .userEntered: "Manual"
        case .usingPoints: "Weights"
        }
    }
}

struct WeightChange: Hashable, Codable {

    var kg: Double?
    var type: WeightChangeType = .usingPoints
    var points: Points? = nil
    
    struct Points: Hashable, Codable {
        var start: WeightChangePoint
        var end: WeightChangePoint
        
        init(date: Date, interval: HealthInterval) {
            self.end = .init(date: date)
            self.start = .init(date: interval.startDate(with: date))
        }
        
        var weightChangeInKg: Double? {
            guard let endKg = end.kg, let startKg = start.kg else { return nil }
            return endKg - startKg
        }
    }
    
    var isEmpty: Bool {
        kg == nil
    }

    var energyEquivalentInKcal: Double? {
        guard let kg else { return nil }
//        454 g : 3500 kcal
//        delta : x kcal
        return (3500 * kg) / BodyMassUnit.lb.convert(1, to: .kg)
    }
    
    func energyEquivalent(in energyUnit: EnergyUnit) -> Double? {
        guard let kcal = energyEquivalentInKcal else { return nil }
        return EnergyUnit.kcal.convert(kcal, to: energyUnit)
    }
}

import Foundation

public enum MaintenanceCalculationError: Int, Error, Codable {
    case noWeightData = 1
    case noNutritionData
    case noWeightOrNutritionData
    case weightChangeExceedsNutrition
    
    var message: String {
        switch self {
        case .noWeightData:
//            "You do not have enough weight data over the prior week to make a calculation."
            "You need to set your weight change to make a calculation."
        case .noNutritionData:
            "You need to have at least one day's dietary energy to make a calculation."
        case .noWeightOrNutritionData:
            "You need to set your weight change and dietary energy consumed to make an adaptive calculation."
        case .weightChangeExceedsNutrition:
            "Your weight gain far exceeds the dietary energy, making the calculation invalid. Make sure you have accounted for all the dietary energy you consumed."
        }
    }
    
    var title: String {
        switch self {
        case .noWeightData:
            "No Weight Change"
        case .noNutritionData:
            "No Dietary Energy"
        case .noWeightOrNutritionData:
            "No Weight Change and Dietary Energy"
        case .weightChangeExceedsNutrition:
            "Invalid Data"
        }
    }
}

extension HealthDetails.Maintenance.Adaptive {
    static func calculate(
        weightChange: WeightChange,
        dietaryEnergy: DietaryEnergy,
        interval: HealthInterval
    ) -> Result<Double, MaintenanceCalculationError> {
        
        guard let weightDeltaInKcal = weightChange.energyEquivalentInKcal,
              let dietaryEnergyTotal = dietaryEnergy.totalInKcal
        else {
            return switch (weightChange.isEmpty, dietaryEnergy.isEmpty) {
            case (true, false): .failure(.noWeightData)
            case (false, true): .failure(.noNutritionData)
            default:            .failure(.noWeightOrNutritionData)
            }
        }
        
        let value = (dietaryEnergyTotal - weightDeltaInKcal) / Double(interval.numberOfDays)
        
        guard value > 0 else {
            return .failure(.weightChangeExceedsNutrition)
        }
        
        return .success(max(value, 0))
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
            var kcal: Double?
            var error: MaintenanceCalculationError?
            var interval: HealthInterval
            
            var dietaryEnergy = DietaryEnergy()
            var weightChange = WeightChange()
            
            init(
                kcal: Double? = nil,
                interval: HealthInterval = .init(1, .week),
                dietaryEnergy: DietaryEnergy = DietaryEnergy(),
                weightChange: WeightChange = WeightChange()
            ) {
                self.kcal = kcal
                self.interval = interval
                self.dietaryEnergy = dietaryEnergy
                self.weightChange = weightChange
                
                let result = Self.calculate(
                    weightChange: weightChange,
                    dietaryEnergy: dietaryEnergy,
                    interval: interval
                )
                switch result {
                case .success(let value):
                    self.kcal = value
                    self.error = nil
                case .failure(let error):
                    self.kcal = nil
                    self.error = error
                }
            }
            
            struct DietaryEnergy: Hashable, Codable {
                var kcalPerDay: Double?
                var points: [DietaryEnergyPoint]
                
                init(points: [DietaryEnergyPoint] = []) {
                    var points = points
                    points.fillAverages()
                    self.points = points
                    self.kcalPerDay = points.average
                }
                
                var isEmpty: Bool {
                    !points.contains(where: { $0.kcal != nil })
                }
                
                var totalInKcal: Double? {
                    guard !isEmpty else { return nil }
                    return points
                        .compactMap { $0.kcal }
                        .reduce(0) { $0 + $1 }
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
        var measurements: [LeanBodyMassMeasurement] = []
        var deletedHealthKitMeasurements: [LeanBodyMassMeasurement] = []
    }
}

//MARK: - Weight
extension HealthDetails {
    struct Weight: Hashable, Codable {
        var weightInKg: Double? = nil
        var measurements: [WeightMeasurement] = []
        var deletedHealthKitMeasurements: [WeightMeasurement] = []
    }
}

extension Array where Element == HealthDetails.Weight {
    var averageValue: Double? {
        compactMap{ $0.weightInKg }.average
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

extension Double {
    
    func convertEnergy(from fromUnit: EnergyUnit, to toUnit: EnergyUnit) -> Double {
        fromUnit.convert(self, to: toUnit)
//            .rounded(.towardZero)
    }
}
extension Optional where Wrapped == Double {

    func convertBodyMass(from fromUnit: BodyMassUnit, to toUnit: BodyMassUnit) -> Double? {
        guard let self else { return nil }
        return fromUnit.convert(self, to: toUnit)
    }

    func convertEnergy(from fromUnit: EnergyUnit, to toUnit: EnergyUnit) -> Double? {
        guard let self else { return nil }
        return fromUnit.convert(self, to: toUnit)
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
    }
}

import HealthKit

extension HealthDetails.Height {
    
    mutating func addHealthKitSample(_ sample: HKQuantitySample) {
        
        guard !measurements.contains(where: { $0.healthKitUUID == sample.uuid }),
              !deletedHealthKitMeasurements.contains(where: { $0.healthKitUUID == sample.uuid })
        else {
            return
        }
        measurements.append(HeightMeasurement(sample: sample))
        measurements.sort()
        heightInCm = measurements.last?.heightInCm
    }
    
    func valueString(in unit: HeightUnit) -> String {
        heightInCm.valueString(convertedFrom: .cm, to: unit)
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
        self.init(id: id, date: date, value: heightInCm, healthKitUUID: healthKitUUID)
    }

    init(
        id: UUID = UUID(),
        date: Date,
        value: Double,
        healthKitUUID: UUID? = nil
    ) {
        self.id = id
        self.healthKitUUID = healthKitUUID
        self.date = date
        self.heightInCm = value
    }
    
    init(sample: HKQuantitySample) {
        self.id = UUID()
        self.healthKitUUID = sample.uuid
        self.date = sample.date
        self.heightInCm = sample.quantity.doubleValue(for: .meterUnit(with: .centi))
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
        self.init(id: id, date: date, value: weightInKg, healthKitUUID: healthKitUUID)
    }

    init(
        id: UUID = UUID(),
        date: Date,
        value: Double,
        healthKitUUID: UUID? = nil
    ) {
        self.id = id
        self.healthKitUUID = healthKitUUID
        self.date = date
        self.weightInKg = value
    }
}

struct LeanBodyMassMeasurement: Hashable, Identifiable, Codable {
    let id: UUID
    let source: LeanBodyMassSource
    let date: Date
    let leanBodyMassInKg: Double
    let fatPercentage: Double? /// e.g. 10 for 10%

    init(
        id: UUID,
        date: Date,
        value: Double,
        healthKitUUID: UUID?
    ) {
        self.id = id
        self.source = if let healthKitUUID {
            .healthKit(healthKitUUID)
        } else {
            .userEntered
        }
        self.date = date
        self.leanBodyMassInKg = value
        self.fatPercentage = nil
    }
    
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
