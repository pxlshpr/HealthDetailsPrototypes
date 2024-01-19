import SwiftUI

enum DietaryEnergyPointSource: Int, Codable, CaseIterable, Identifiable {
    case log = 1
    case healthKit
    case fasted
    case manual
    case notCounted

    var id: Int {
        rawValue
    }

    var emptyValueString: String {
        switch self {
        case .notCounted:   "Excluded"
        case .healthKit:    "No Data"
        default:            NotSetString
        }
    }
        
    var image: String {
        switch self {
        case .log:          "book.closed"
        case .healthKit:    "pencil"
        case .fasted:       ""
        case .manual:  "pencil"
        case .notCounted:   "pencil.slash"
        }
    }

    var name: String {
        switch self {
        case .log:          "Logged Energy"
        case .healthKit:    "Apple Health Data"
        case .fasted:       "Mark as Fasted"
        case .manual:  "Enter Manually"
        case .notCounted:   "Not Counted"
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
        default:    Color(.systemGray4)
        }
    }
    
    var foregroundColor: Color {
        switch self {
        default:    Color(.label)
        }
    }
}
