import Foundation

enum WeightChangeType: Int, Hashable, Codable, CaseIterable, Identifiable {
    case weights = 1
    case manual
    
    var id: Int { rawValue }
    
    var name: String {
        switch self {
        case .manual: "Manual"
        case .weights: "Weights"
        }
    }
}
