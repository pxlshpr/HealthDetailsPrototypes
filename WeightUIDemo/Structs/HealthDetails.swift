import Foundation

struct HealthDetails: Hashable, Codable {
 
    let date: Date
    var sex: BiologicalSex = .notSet
    var age: Age? = nil
    var smokingStatus: SmokingStatus = .notSet
    var pregnancyStatus: PregnancyStatus = .notSet
    var height: Height? = nil
}

//MARK: - Height

extension HealthDetails {
    struct Height: Hashable, Codable {
        var heightInCm: Double
        var measurements: [HeightMeasurement]
        var deletedHealthKitMeasurements: [HeightMeasurement]
        var isSynced: Bool
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

    func valueString(unit: String) -> String {
        "\(heightInCm.clean) \(unit)"
    }
    
    var dateString: String {
        date.shortTime
    }
    
    var isFromHealthKit: Bool {
        healthKitUUID != nil
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
