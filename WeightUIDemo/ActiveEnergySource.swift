import Foundation

public enum ActiveEnergySource: Int16, Codable, CaseIterable {
    case healthKit = 1
    case activityLevel
    case userEntered
    
    var name: String {
        switch self {
        case .healthKit:        "Apple Health"
        case .activityLevel:    "Activity Level"
        case .userEntered:      "Custom"
        }
    }
}

extension ActiveEnergySource: Pickable {
    
    public var pickedTitle: String {
        switch self {
        case .healthKit:        "Sync with Apple Health"
        case .activityLevel:    "Activity Level Multiplier"
        case .userEntered:      "Custom"
        }
    }
    
    public var menuTitle: String { pickedTitle }
    
    public var menuImage: String {
        switch self {
        case .healthKit:        "heart.fill"
        case .activityLevel:    "dial.medium.fill"
        case .userEntered:      ""
        }
    }
    
    public static var `default`: ActiveEnergySource { .activityLevel }
}
