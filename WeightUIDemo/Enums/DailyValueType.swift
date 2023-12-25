import Foundation

enum DailyValueType: CaseIterable, Hashable {
    case average
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
            "The average is being used."
        case .last:
            "The last entry is being used."
        case .first:
            "The first entry is being used."
        }
    }
}
