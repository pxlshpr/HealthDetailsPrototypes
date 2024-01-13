import SwiftUI

enum DietaryEnergyPointSource: Int, Codable, CaseIterable, Identifiable {
    case log = 1
    case healthKit
    case fasted
    case userEntered
    case notCounted

    var id: Int {
        rawValue
    }

    var emptyValueString: String {
        switch self {
        case .notCounted:   "Excluded"
        case .healthKit:    "No Data"
        default:            "Not Set"
        }
    }
        
    var image: String {
        switch self {
        case .log:          "book.closed"
        case .healthKit:    "pencil"
        case .fasted:       ""
        case .userEntered:  "pencil"
        case .notCounted:   "pencil.slash"
//        case .notCounted:   "questionmark.square.dashed"
//        case .notCounted:   "circle.slash"
        }
    }

//    var name: String {
//        switch self {
//        case .log:          "Use Log"
//        case .healthKit:    "Use Apple Health"
//        case .fasted:       "Set as Fasted"
//        case .userEntered:  "Enter Manually"
//        case .notCounted:   "Not Counted" /// "Exclude and Use Average"
//        }
//    }

    var name: String {
        switch self {
        case .log:          "Logged Energy"
        case .healthKit:    "Apple Health Data"
        case .fasted:       "Mark as Fasted"
        case .userEntered:  "Enter Manually"
        case .notCounted:   "Not Counted"
//        case .notCounted:   "Not Included"
//        case .notCounted:   "Exclude and Use Average"
//        case .notCounted:   "Exclude this Day"
        }
    }

    var imageScale: CGFloat {
        switch self {
        case .notCounted:   0.85
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
