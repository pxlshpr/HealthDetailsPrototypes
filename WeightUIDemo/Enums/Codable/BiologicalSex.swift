import Foundation
import PrepShared

enum BiologicalSex: Int, Codable, CaseIterable {
    case female = 1
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
