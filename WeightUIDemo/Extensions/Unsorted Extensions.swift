import Foundation

extension Date {
    func moveYearBy(_ yearIncrement: Int) -> Date {
        var components = DateComponents()
        components.year = yearIncrement
        return Calendar.current.date(byAdding: components, to: self)!
    }

    var dateComponentsWithoutTime: DateComponents {
        Calendar.current.dateComponents(
            [.year, .month, .day],
            from: self
        )
    }
    
    var age: Int {
        dateComponentsWithoutTime.age
    }
}
public extension DateComponents {
    var age: Int {
        let calendar = Calendar.current
        let now = Date().dateComponentsWithoutTime
        let ageComponents = calendar.dateComponents([.year], from: self, to: now)
        return ageComponents.year ?? 0
    }
}

extension Int {
    var dateOfBirth: Date {
        Date.now.moveYearBy(-self)
    }
}

extension Double {
    var formattedEnergy: String {
        let rounded = self.rounded()
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let number = NSNumber(value: Int(rounded))
        
        guard let formatted = numberFormatter.string(from: number) else {
            return "\(Int(rounded))"
        }
        return formatted
    }
}

public extension String {
    var sanitizedDouble: String {
        var chars: [Character] = []
        var hasPeriod: Bool = false
        forLoop: for (index, char) in self.enumerated() {
            
            switch char {
            case ".":
                /// Only allow period once, otherwise ignoring it and rest of string
                if hasPeriod {
                    break forLoop
                } else {
                    hasPeriod = true
                    chars.append(char)
                }
                
            case "-":
                /// Only allow negative sign if first character, otherwise ignoring it and rest of string
                guard index == 0 else {
                    break forLoop
                }
                chars.append(char)
                
            default:
                /// Only allow numbers
                guard char.isNumber else {
                    break forLoop
                }
                chars.append(char)
            }
        }
        return String(chars)
    }
}
