import Foundation

enum DailyMeasurementType: Int, CaseIterable, Hashable, Codable {
    case average = 1
    case last
    case first
    
    var name: String {
        switch self {
        case .average:  "Average"
        case .last:     "Last"
        case .first:    "First"
        }
    }

    func description(for healthDetail: HealthDetail) -> String {
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
}
