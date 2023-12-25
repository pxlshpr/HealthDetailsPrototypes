import Foundation

enum MaintenanceType: CaseIterable {
    case adaptive
    case estimated
    
    var name: String {
        switch self {
        case .adaptive: "Adaptive"
        case .estimated: "Estimated"
        }
    }
}
