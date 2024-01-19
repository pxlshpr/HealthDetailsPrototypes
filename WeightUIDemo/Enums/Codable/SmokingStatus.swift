import Foundation
import PrepShared

public enum SmokingStatus: Int16, Codable, CaseIterable {
    case nonSmoker = 1
    case smoker
    case notSet
}

public extension SmokingStatus {
    
    var name: String {
        switch self {
        case .smoker:       "Smoker"
        case .nonSmoker:    "Non-smoker"
        case .notSet:       NotSetString
        }
    }
}

extension SmokingStatus: Pickable {
    public var pickedTitle: String { self.name }
    public var menuTitle: String { self.name }
    public static var `default`: SmokingStatus { .notSet }
}
