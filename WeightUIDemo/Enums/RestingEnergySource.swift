import Foundation
import PrepShared

public enum RestingEnergySource: Int, Codable, CaseIterable {
    case equation = 1
    case healthKit
    case userEntered
    
    var name: String {
        switch self {
        case .healthKit:    "Apple Health"
        case .equation:     "Equation"
        case .userEntered:  "Manual"
        }
    }
    
}

extension RestingEnergySource: Pickable {
    
    public var pickedTitle: String {
        menuTitle
    }
    
    public var menuTitle: String {
        switch self {
//        case .healthKit:    "Health app"
        case .healthKit:    "Sync with Apple Health"
        case .equation:     "Equation"
//        case .userEntered:  "Entered manually"
        case .userEntered:  "Manual"
        }
    }
    
    public var menuImage: String {
        switch self {
        case .healthKit:    "heart.fill"
        case .equation:     "function"
        case .userEntered:  ""
        }
    }
    
    public static var `default`: RestingEnergySource { .equation }
}
