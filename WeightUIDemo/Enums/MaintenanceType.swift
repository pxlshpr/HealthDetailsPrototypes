import Foundation

enum MaintenanceType: Int, Codable, CaseIterable {
    case adaptive = 1
    case estimated
    
    var name: String {
        switch self {
        case .adaptive: "Adaptive"
        case .estimated: "Estimated"
        }
    }
}
