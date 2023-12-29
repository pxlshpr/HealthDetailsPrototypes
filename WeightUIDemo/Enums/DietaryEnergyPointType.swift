import SwiftUI

enum DietaryEnergyPointType: Int, CaseIterable, Identifiable {
    case log = 1
    case healthKit
    case fasted
    case useAverage
    case custom

    var id: Int {
        rawValue
    }
    
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
        case .log:          "Use Log"
        case .healthKit:    "Use Apple Health"
        case .fasted:       "Set as Fasted"
        case .custom:       "Enter Manually"
        case .useAverage:   "Exclude and Use Average"
        }
    }
    
    var imageScale: CGFloat {
        switch self {
        case .useAverage:   0.85
        default:            1.0
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
