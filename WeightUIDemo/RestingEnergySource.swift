import Foundation

public enum RestingEnergySource: Int16, Codable, CaseIterable {
    case healthKit = 1
    case equation
    case userEntered
    
    var name: String {
        switch self {
        case .healthKit:    "Apple Health"
        case .equation:     "Equation"
        case .userEntered:  "Custom"
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
        case .userEntered:  "Custom"
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
