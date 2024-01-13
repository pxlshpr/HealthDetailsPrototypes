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

    func description(for healthDetail: HealthDetail) -> String {
//        let suffix = "measurements for the day will always be used"
//        let suffix = "measurements will always be used for the day"
        let suffix = "measurements will be used for the day"
        return switch self {
        case .average:
            "The average of your \(healthDetail.name.lowercased()) \(suffix)."
        case .last:
            "The last of your \(healthDetail.name.lowercased()) \(suffix)."
        case .first:
            "The first of your \(healthDetail.name.lowercased()) \(suffix)."
        }
    }
    
//    var description: String {
//        switch self {
//        case .average:
//            "The average of the measurements will be used."
//        case .last:
//            "The last of the measurements will be used."
//        case .first:
//            "The first of the measurements will be used."
//        }
//    }
}
