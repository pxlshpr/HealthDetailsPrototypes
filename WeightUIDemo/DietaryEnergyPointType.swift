import SwiftUI

enum DietaryEnergyPointType: CaseIterable {
    case log
    case healthKit
    case fasted
    case custom
    case notIncluded

    var image: String {
        switch self {
        case .log:          "book.closed"
        case .healthKit:    "pencil"
        case .fasted:       ""
        case .custom:       "pencil"
        case .notIncluded:      "circle.slash"
        }
    }

    var name: String {
        switch self {
        case .log:          "Log"
        case .healthKit:    "Apple Health"
        case .fasted:       "Fasted"
        case .custom:       "Custom"
        case .notIncluded:  "Not Included"
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
