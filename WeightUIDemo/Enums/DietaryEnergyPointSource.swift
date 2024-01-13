import SwiftUI

enum DietaryEnergyPointSource: Int, Codable, CaseIterable, Identifiable {
    case log = 1
    case healthKit
    case fasted
    case userEntered
    case useAverage

    var id: Int {
        rawValue
    }

    var emptyValueString: String {
        switch self {
        case .useAverage:   "Excluded"
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
        case .useAverage:   "pencil.slash"
//        case .useAverage:   "questionmark.square.dashed"
//        case .useAverage:   "circle.slash"
        }
    }

//    var name: String {
//        switch self {
//        case .log:          "Use Log"
//        case .healthKit:    "Use Apple Health"
//        case .fasted:       "Set as Fasted"
//        case .userEntered:  "Enter Manually"
//        case .useAverage:   "Not Counted" /// "Exclude and Use Average"
//        }
//    }

    var name: String {
        switch self {
        case .log:          "Logged Energy"
        case .healthKit:    "Apple Health Data"
        case .fasted:       "Mark as Fasted"
        case .userEntered:  "Enter Manually"
        case .useAverage:   "Not Included" /// "Exclude and Use Average"
//        case .useAverage:   "Exclude this Day" /// "Exclude and Use Average"
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
