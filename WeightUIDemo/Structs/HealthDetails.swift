import Foundation

struct HealthDetails: Hashable, Codable {
 
    let date: Date
    var sex: BiologicalSex = .notSet
    var age: Age? = nil
    var smokingStatus: SmokingStatus = .notSet
    var pregnancyStatus: PregnancyStatus = .notSet
    var height = Height()
    var weight = Weight()
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

//MARK: - Height

extension HealthDetails {
    struct Height: Hashable, Codable {
        var heightInCm: Double? = nil
        var measurements: [HeightMeasurement] = []
        var deletedHealthKitMeasurements: [HeightMeasurement] = []
        var isSynced: Bool = false
    }
}

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
