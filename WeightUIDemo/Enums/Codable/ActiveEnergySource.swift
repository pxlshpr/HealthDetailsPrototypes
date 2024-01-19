import Foundation
import PrepShared

public enum ActiveEnergySource: Int, Codable, CaseIterable {
    case activityLevel = 1
    case healthKit
    case manual
    
    var name: String {
        switch self {
        case .healthKit:        "Apple Health"
        case .activityLevel:    "Activity Level"
        case .manual:      "Custom"
        }
    }
}

extension ActiveEnergySource: Pickable {
    
    public var pickedTitle: String {
        switch self {
        case .healthKit:        "Sync with Apple Health"
        case .activityLevel:    "Activity Level Multiplier"
        case .manual:      "Custom"
        }
    }
    
    public var menuTitle: String { pickedTitle }
    
    public var menuImage: String {
        switch self {
        case .healthKit:        "heart.fill"
        case .activityLevel:    "dial.medium.fill"
        case .manual:      ""
        }
    }
    
    public static var `default`: ActiveEnergySource { .activityLevel }
}
