import Foundation

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
