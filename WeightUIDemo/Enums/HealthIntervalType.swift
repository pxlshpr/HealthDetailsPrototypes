import Foundation
import PrepShared

public enum HealthIntervalType: Int16, Codable, CaseIterable {
    case average = 1
    case sameDay
    case previousDay
    
    var name: String {
        switch self {
        case .average:      "Daily Average"
//        case .sameDay:      "Same Day"
//        case .previousDay:  "Previous Day"
        case .sameDay:      "Today's Data"
        case .previousDay:  "Yesterday's Data"
        }
    }

    func dateDescription(_ date: Date, interval: HealthInterval) -> String {
        let isPast = !date.isToday
        return switch self {
        case .average:
            "the past \(interval.description)"
        case .sameDay:
            if isPast {
                "\(date.shortDateString)"
            } else {
                "today"
            }
        case .previousDay:
            if isPast {
                "\(date.moveDayBy(-1).shortDateString)"
            } else {
                "yesterday"
            }
        }
    }

//    func footerDescription_(_ pastDate: Date?, interval: HealthInterval, isResting: Bool = false) -> String {
//        let energyType = isResting ? "Resting" : "Active"
//        let dateDescription = dateDescription(pastDate, interval: interval)
//        return switch self {
//        case .average:
//            "Using the average \(energyType) Energy of \(dateDescription)."
//        default:
//            "Using the Resting \(energyType) recorded for \(dateDescription)."
//        }
//    }
    
    func footerDescription(_ date: Date, interval: HealthInterval, isResting: Bool) -> String {
        let energyType = isResting ? "Resting" : "Active"
        let isPast = !date.isToday
        return switch self {
        case .average:
//            "Using the average \(energyType) Energy of the past \(interval.description)."
            "This will always use the average \(energyType) Energy of the previoius \(interval.description)."
        case .sameDay:
            if isPast {
//                "Using the Resting Energy recorded for \(pastDate.shortDateString)."
                "This will always use the \(energyType) energy recorded on the same day, which–for this date–is \(date.shortDateString)."
            } else {
//                "Using the Resting Energy recorded for today."
                "This will always use the \(energyType) energy recorded on the same day."
            }
        case .previousDay:
            if isPast {
//                "Using the Resting Energy recorded for \(pastDate.moveDayBy(-1).shortDateString)."
                "This will always use the \(energyType) Energy recorded for the previous day, which–for this date–is \(date.moveDayBy(-1).shortDateString)."
            } else {
//                "Using the Resting Energy recorded for yesterday."
                "This will always use the \(energyType) Energy recorded for the previous day."
            }
        }
    }
}

extension HealthIntervalType: Pickable {

    public var pickedTitle: String {
        switch self {
        case .average:      "Daily average"
        case .sameDay:      "Same day"
        case .previousDay:  "Previous day"
        }
    }
    
    public var menuTitle: String {
        pickedTitle
    }

    public var description: String? {
        switch self {
        case .average:
//            "Use the daily average of a specified period before this day"
//            "The daily average of the resting energy for a period before this day will be used"
            "The daily average for a period before this day will be used"
        case .sameDay:
//            "The resting energy for today in Apple Health will always be used"
            "The total for today will always be used"
        case .previousDay:
//            "Use the value for the day before this date"
//            "The resting energy for yesterday in Apple Health will be used"
            "The total for yesterday will be used"
        }
    }

    public static var `default`: HealthIntervalType { .average }
}
