import Foundation
import PrepShared

struct HealthDetails: Hashable, Codable {
 
    let date: Date
    var sex: BiologicalSex = .notSet
    var age: Age? = nil
    var smokingStatus: SmokingStatus = .notSet
    var pregnancyStatus: PregnancyStatus = .notSet
    var height = Height()
    var weight = Weight()
    var leanBodyMass = LeanBodyMass()
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

extension Optional where Wrapped == Double {
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

extension HealthDetails {
    struct Age: Hashable, Codable {
        var years: Int?
        var dateOfBirthComponents: DateComponents?
        
        init(years: Int) {
            self.years = years
            self.dateOfBirthComponents = years.dateOfBirth.dateComponentsWithoutTime
        }
        
        init(dateOfBirth: Date) {
            self.years = dateOfBirth.age
            self.dateOfBirthComponents = dateOfBirth.dateComponentsWithoutTime
        }

    }
}

extension HealthDetails.Age {
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
            years = newValue.age
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

