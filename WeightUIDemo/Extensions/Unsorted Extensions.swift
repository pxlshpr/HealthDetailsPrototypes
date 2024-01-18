import Foundation
import PrepShared

extension Array where Element == Double {
    var average: Double? {
        guard !isEmpty else { return nil }
        let sum = self
            .reduce(0, +)
        return sum / Double(count)
    }
}

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
//    init?(fromDateString string: String) {
//        let dateFormatter = DateFormatter()
//        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
//        dateFormatter.dateFormat = "yyyy_MM_dd"
//        guard let date = dateFormatter.date(from: string) else {
//            return nil
//        }
//        self = date
//    }
    
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
    
    var ageInYears: Int {
        dateComponentsWithoutTime.ageInYears
    }
}
public extension DateComponents {
    var ageInYears: Int {
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
    
    var dateOfBirthComponents: DateComponents {
        dateOfBirth.dateComponentsWithoutTime
    }
}

//extension Double {
//    var formattedEnergy: String {
//        let rounded = self.rounded()
//        
//        let numberFormatter = NumberFormatter()
//        numberFormatter.numberStyle = .decimal
//        let number = NSNumber(value: Int(rounded))
//        
//        guard let formatted = numberFormatter.string(from: number) else {
//            return "\(Int(rounded))"
//        }
//        return formatted
//    }
//}

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

import PrepShared

extension HeightUnit: HealthUnit {
    public static var secondaryUnit: String? { "in" }
    public var hasTwoComponents: Bool { self == .ft }
    
//    public func intComponent(_ value: Double, in other: HeightUnit) -> Int? {
//        guard other.hasTwoComponents else {
//            return nil
//        }
//        let converted = convert(value, to: other)
//        return Int(converted)
//    }
//    
//    public func doubleComponent(_ value: Double, in other: HeightUnit) -> Double {
//        let converted = convert(value, to: other)
//        return if other.hasTwoComponents {
//            (converted - converted.whole) * Self.upperSecondaryUnitValue
//        } else {
//            converted
//        }
//    }
    
    public func intComponent(_ value: Double, in other: HeightUnit) -> Int? {
        let converted = convert(value, to: other)
        return other.intComponent(of: converted)
    }
    
    public func doubleComponent(_ value: Double, in other: HeightUnit) -> Double {
        let converted = convert(value, to: other)
        return other.doubleComponent(of: converted)
    }
    
    public func intComponent(of value: Double) -> Int? {
        guard hasTwoComponents else { return nil }
        return Int(value)
    }
    
    public func doubleComponent(of value: Double) -> Double {
        return if hasTwoComponents {
            (value - value.whole) * Self.upperSecondaryUnitValue
        } else {
            value
        }
    }
    
    public var intUnitString: String? {
        self == .ft ? "ft" : nil
    }
    
    public var doubleUnitString: String {
        self == .ft ? "in" : abbreviation
    }
}



extension BodyMassUnit: HealthUnit {
    public static var secondaryUnit: String? { "lb" }
    public var hasTwoComponents: Bool { self == .st }
    
    public func intComponent(_ value: Double, in other: BodyMassUnit) -> Int? {
        let converted = convert(value, to: other)
        return other.intComponent(of: converted)
//        guard other.hasTwoComponents else {
//            return nil
//        }
//        let converted = convert(value, to: other)
//        return Int(converted)
    }
    
    public func doubleComponent(_ value: Double, in other: BodyMassUnit) -> Double {
        let converted = convert(value, to: other)
        return other.doubleComponent(of: converted)
//        return if other.hasTwoComponents {
//            (converted - converted.whole) * Self.upperSecondaryUnitValue
//        } else {
//            converted
//        }
    }
    
    public func intComponent(of value: Double) -> Int? {
        guard hasTwoComponents else { return nil }
        return Int(value)
    }
    
    public func doubleComponent(of value: Double) -> Double {
        return if hasTwoComponents {
            (value - value.whole) * Self.upperSecondaryUnitValue
        } else {
            value
        }
    }
    
    public var intUnitString: String? {
        self == .st ? "st" : nil
    }
    
    public var doubleUnitString: String {
        self == .st ? "lb" : abbreviation
    }
}

//TODO: Move this into HealthUnit
extension HeightUnit {
    func convert(_ int: Int, _ double: Double, to other: HeightUnit) -> Double {
        let value = if self.hasTwoComponents {
            Double(int) + (double / Self.upperSecondaryUnitValue)
        } else {
            double
        }
        return self.convert(value, to: other)
    }
}

extension BodyMassUnit {
    func convert(_ int: Int, _ double: Double, to other: BodyMassUnit) -> Double {
        let value = if self.hasTwoComponents {
            Double(int) + (double / Self.upperSecondaryUnitValue)
        } else {
            double
        }
        return self.convert(value, to: other)
    }
}

extension HeightUnit {
    var secondaryUnit: String? {
        hasTwoComponents ? "in" : nil
    }
    
    static var upperSecondaryUnitValue: Double {
        /// 12 inches equal 1 feet
        12
    }
}

extension BodyMassUnit {
    var secondaryUnit: String? {
        hasTwoComponents ? "lb" : nil
    }
    
    static var upperSecondaryUnitValue: Double {
        /// 14 pounds equals 1 stone
        14
    }
}

extension Double {
    
    var cleanHealth: String {
        /// round it off to a reasonable number first to avoid numbers like `7.00000000000009` resulting in `7.0`
        let value = self.rounded(toPlaces: 1).truncatingRemainder(dividingBy: 1)
        if value == 0 {
            return String(format: "%.0f", self.rounded(toPlaces: 1))
        } else {
            return String(self.rounded(toPlaces: 1))
        }
    }
}

extension Date {
    var healthTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self).lowercased()
    }
}

import SwiftUI

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

import HealthKit
import PrepShared

public extension EnergyUnit {
    var healthKitUnit: HKUnit {
        switch self {
        case .kcal:
            return .kilocalorie()
        case .kJ:
            return .jouleUnit(with: .kilo)
        }
    }
}

public extension ClosedRange<Date> {
    
    var days: [Date] {
        var days: [Date] = []
        let calendar = Calendar(identifier: .gregorian)
        calendar.enumerateDates(
            startingAfter: lowerBound,
            matching: DateComponents(hour: 0, minute: 0, second:0),
            matchingPolicy: .nextTime)
        { (date, _, stop) in
            guard let date = date, date <= upperBound else {
                stop = true
                return
            }
            days.append(date)
        }
        return days
    }
}

import SwiftUI
import SwiftHaptics

public var textSelectionTapGesture: some Gesture {
    TapGesture().onEnded {
        Haptics.selectionFeedback()
        DispatchQueue.main.async {
            sendSelectAllTextAction()
        }
    }
}

public func sendSelectAllTextAction() {
    UIApplication.shared.sendAction(#selector(UIResponder.selectAll),
        to: nil, from: nil, for: nil
    )
}
