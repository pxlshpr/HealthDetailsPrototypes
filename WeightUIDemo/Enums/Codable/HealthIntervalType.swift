import Foundation
import PrepShared

public enum HealthIntervalType: Int16, Codable, CaseIterable {
    case average = 1
    case sameDay
    case previousDay
    
    var name: String {
        switch self {
        case .average:      "Daily Average"
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

    func footerDescription(_ date: Date, interval: HealthInterval, isResting: Bool) -> String {
        let energyType = isResting ? "Resting" : "Active"
        let isPast = !date.isToday
        return switch self {
        case .average:
            "This will always use the average \(energyType) Energy of the previoius \(interval.description)."
        case .sameDay:
            if isPast {
                "This will always use the \(energyType) energy recorded on the same day, which–for this date–is \(date.shortDateString)."
            } else {
                "This will always use the \(energyType) energy recorded on the same day."
            }
        case .previousDay:
            if isPast {
                "This will always use the \(energyType) Energy recorded for the previous day, which–for this date–is \(date.moveDayBy(-1).shortDateString)."
            } else {
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
            "The daily average for a period before this day will be used"
        case .sameDay:
            "The total for today will always be used"
        case .previousDay:
            "The total for yesterday will be used"
        }
    }

    public static var `default`: HealthIntervalType { .average }
}
