import Foundation

public extension Double {
    
    var roundedToOnePlace: String {
        /// round it off to a reasonable number first to avoid numbers like `7.00000000000009` resulting in `7.0`
        let value = self.rounded(toPlaces: 6).truncatingRemainder(dividingBy: 1)
        if value == 0 {
            return String(format: "%.0f", self.rounded(toPlaces: 1))
        } else {
            return String(self.rounded(toPlaces: 1))
        }
    }
}

public extension Date {
    var shortDateString: String {
        let formatter = DateFormatter()
        if self.year == Date().year {
            formatter.dateFormat = "d MMM"
        } else {
            formatter.dateFormat = "d MMM yyyy"
        }
        return formatter.string(from: self)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd"
        return formatter.string(from: self)
    }
}

extension Date {
    init?(fromDateString string: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy_MM_dd"
        guard let date = dateFormatter.date(from: string) else {
            return nil
        }
        self = date
    }
    
    init?(fromDateTimeString string: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy_MM_dd-HH_mm"
        guard let date = dateFormatter.date(from: string) else {
            return nil
        }
        self = date
    }
    
    init?(fromShortTimeString timeString: String, on date: Date = Date.now) {
        let dateString = date.dateString
        let dateTimeString = "\(dateString)-\(timeString)"
        self.init(fromDateTimeString: dateTimeString)
    }
}

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
