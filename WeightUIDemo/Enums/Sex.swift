import Foundation

public enum Sex: Int16, Codable, CaseIterable {
    case female = 1
    case male
    case other
}

public extension Sex {
    
    var name: String {
        switch self {
        case .female:   "Female"
        case .male:     "Male"
        case .other:    "Other"
        }
    }
}

extension Sex: Pickable {
    public var pickedTitle: String { self.name }
    public var menuTitle: String { self.name }
    public static var `default`: Sex { .other }
}
