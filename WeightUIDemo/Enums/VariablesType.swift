import Foundation

enum VariablesType {
    case equation
    case goal
    case dailyValue
    
    var name: String {
        switch self {
        case .equation:     "calculation"
        case .goal:         "goal"
        case .dailyValue:   "daily value"
        }
    }
    
    var title: String {
        switch self {
        case .equation:     "Equation Variables"
        case .goal:         "Goal Variables"
        case .dailyValue:   "Daily Value Variables"
        }
    }
}
