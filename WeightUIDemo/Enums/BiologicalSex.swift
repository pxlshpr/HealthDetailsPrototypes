import Foundation
import PrepShared

enum BiologicalSex: Codable, CaseIterable {
    case female
    case male
    case notSet
}

extension BiologicalSex {
    
    var name: String {
        switch self {
        case .female:   "Female"
        case .male:     "Male"
        case .notSet:   NotSetString
        }
    }
}

extension BiologicalSex: Pickable {
    var pickedTitle: String { self.name }
    var menuTitle: String { self.name }
    static var `default`: BiologicalSex { .notSet }
}
