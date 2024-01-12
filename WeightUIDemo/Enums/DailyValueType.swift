import Foundation

enum DailyValueType: Int, CaseIterable, Hashable, Codable {
    case average = 1
    case last
    case first
    
    var name: String {
        switch self {
        case .average:
            "Average"
        case .last:
            "Last"
        case .first:
            "First"
        }
    }
    
    var description: String {
        switch self {
        case .average:
            "The average of the measurements will be used."
        case .last:
            "The last of the measurements will be used."
        case .first:
            "The first of the measurements will be used."
        }
    }
}
