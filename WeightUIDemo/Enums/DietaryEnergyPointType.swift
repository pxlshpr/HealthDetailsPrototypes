import SwiftUI

enum DietaryEnergyPointType: CaseIterable {
    case log
    case healthKit
    case fasted
    case useAverage
    case custom

    var image: String {
        switch self {
        case .log:          "book.closed"
        case .healthKit:    "pencil"
        case .fasted:       ""
        case .custom:       "pencil"
        case .useAverage:   "circle.slash"
        }
    }

    var name: String {
        switch self {
        case .log:          "Log"
        case .healthKit:    "Apple Health"
        case .fasted:       "Fasted"
        case .custom:       "Custom"
        case .useAverage:   "Use Average"
        }
    }

    var backgroundColor: Color {
        switch self {
//                case .log:  Color.accentColor
        default:    Color(.systemGray4)
        }
    }
    
    var foregroundColor: Color {
        switch self {
//                case .log:  .white
        default:    Color(.label)
        }
    }
}
