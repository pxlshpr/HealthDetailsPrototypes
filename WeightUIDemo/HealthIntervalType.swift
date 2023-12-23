import Foundation

public enum HealthIntervalType: Int16, Codable, CaseIterable {
    case average = 1
    case sameDay
    case previousDay
    
    var name: String {
        switch self {
        case .average:      "Daily Average"
        case .sameDay:      "Same Day"
        case .previousDay:  "Previous Day"
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
