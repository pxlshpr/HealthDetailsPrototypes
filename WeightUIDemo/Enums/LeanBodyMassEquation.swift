import Foundation

enum LeanBodyMassEquation: Int, Identifiable, Codable, CaseIterable {
    case boer = 1
    case james
    case hume
    
    var id: Int {
        rawValue
    }
}

extension LeanBodyMassEquation {
    
    var requiredHealthDetails: [HealthDetail] {
        switch self {
        case .boer, .james, .hume:
            [.height, .weight, .sex]
        }
    }
    
    var year: String {
        switch self {
        case .boer:     "1984"
        case .james:    "1976"
        case .hume:     "1966"
        }
    }
    
    var name: String {
        switch self {
        case .boer:     "Boer"
        case .james:    "James"
        case .hume:     "Hume"
        }
    }
    
    /// Equations taken from: [here](https://www.calculator.net/lean-body-mass-calculator.html)
    func calculateInKg(sexIsFemale: Bool, weightInKg weight: Double, heightInCm height: Double) -> Double {
        guard weight > 0, height > 0 else { return 0 }
        let lbm: Double
        switch sexIsFemale {
        case true:
            /// female
            switch self {
            case .boer:
                lbm = (0.252 * weight) + (0.473 * height) - 48.3
            case .james:
                lbm = (1.07 * weight) - (148.0 * pow((weight/height), 2.0))
            case .hume:
                lbm = (0.29569 * weight) + (0.41813 * height) - 43.2933
            }
        case false:
            /// male
            switch self {
            case .boer:
                lbm = (0.407 * weight) + (0.267 * height) - 19.2
            case .james:
                lbm = (1.1 * weight) - (128.0 * pow((weight/height), 2.0))
            case .hume:
                lbm = (0.32810 * weight) + (0.33929 * height) - 29.5336
            }
        }
        return max(lbm, 0)
    }
}