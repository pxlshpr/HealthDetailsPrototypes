import Foundation

struct HealthDetails: Hashable, Codable {
 
    let date: Date
    
    var sex: BiologicalSex = .notSet
    var age: Age? = nil
}

//MARK: - Age

extension HealthDetails {
    struct Age: Hashable, Codable {
        private var value: Int?
        private var dateOfBirthComponents: DateComponents?
        
        init(
            value: Int? = nil,
            dateOfBirth: Date? = nil
        ) {
            self.value = value
            self.dateOfBirthComponents = dateOfBirth?.dateComponentsWithoutTime ?? value?.dateOfBirth.dateComponentsWithoutTime
        }
    }
}

extension HealthDetails.Age {
    var years: Int? {
        get {
            value
        }
        set {
            guard let newValue else {
                value = nil
                dateOfBirthComponents = nil
                return
            }
            
            value = newValue
            dateOfBirth = newValue.dateOfBirth
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
            value = newValue.age
        }
    }
}
