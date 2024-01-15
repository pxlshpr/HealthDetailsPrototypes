import Foundation

enum WeightChangeType: Int, Hashable, Codable, CaseIterable, Identifiable {
    case usingPoints = 1
    case userEntered
    
    var id: Int { rawValue }
    
    var name: String {
        switch self {
        case .userEntered: "Manual"
        case .usingPoints: "Weights"
        }
    }
}
