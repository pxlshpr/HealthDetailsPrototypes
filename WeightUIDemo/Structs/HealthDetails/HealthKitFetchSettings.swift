import Foundation

struct HealthKitFetchSettings: Hashable, Codable {
    var intervalType: HealthIntervalType = .average
    var interval: HealthInterval = .init(3, .day)
    var correctionValue: CorrectionValue? = nil
}
