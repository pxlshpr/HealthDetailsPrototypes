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
        _ id: UUID,
        _ date: Date,
        _ weightInKg: Double,
        _ healthKitUUID: UUID? = nil
    ) {
        self.id = id
        self.healthKitUUID = healthKitUUID
        self.date = date
        self.weightInKg = weightInKg
    }

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

    var timeString: String {
        date.shortTime
    }
    
    var isFromHealthKit: Bool {
        healthKitUUID != nil
    }
    
    var imageType: MeasurementCell.ImageType {
        if isFromHealthKit {
            .healthKit
        } else {
            .systemImage("pencil")
        }
    }
}

extension WeightMeasurement: Comparable {
    static func < (lhs: WeightMeasurement, rhs: WeightMeasurement) -> Bool {
        lhs.date < rhs.date
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
        _ id: UUID,
        _ date: Date,
        _ heightInCm: Double,
        _ healthKitUUID: UUID? = nil
    ) {
        self.id = id
        self.healthKitUUID = healthKitUUID
        self.date = date
        self.heightInCm = heightInCm
    }

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

    var timeString: String {
        date.shortTime
    }
    
    var isFromHealthKit: Bool {
        healthKitUUID != nil
    }
    
    var imageType: MeasurementCell.ImageType {
        if isFromHealthKit {
            .healthKit
        } else {
            .systemImage("pencil")
        }
    }
}

extension HeightMeasurement: Comparable {
    static func < (lhs: HeightMeasurement, rhs: HeightMeasurement) -> Bool {
        lhs.date < rhs.date
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
