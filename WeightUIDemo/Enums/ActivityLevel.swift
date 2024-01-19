import Foundation
import PrepShared

public enum ActivityLevel: Int, Codable, Hashable, CaseIterable {
    case sedentary = 1
    case lightlyActive
    case moderatelyActive
    case active
    case veryActive
}

public extension ActivityLevel {
    
    var name: String {
        switch self {
        case .sedentary:        return "Sedentary"
        case .lightlyActive:    return "Lightly Active"
        case .moderatelyActive: return "Moderately Active"
        case .active:           return "Vigorously Active"
        case .veryActive:       return "Extremely active"
        }
    }
    
    var scaleFactor: Double {
        switch self {
//        case .notSet:           return 1
        case .sedentary:        return 1.2
        case .lightlyActive:    return 1.375
        case .moderatelyActive: return 1.55
        case .active:           return 1.725
        case .veryActive:       return 1.9
        }
    }
}

extension ActivityLevel {
    func calculate(for restingEnergyInKcal: Double) -> Double {
        let total = scaleFactor * restingEnergyInKcal
        return total - restingEnergyInKcal
    }
}

extension ActivityLevel: Pickable {
    public var pickedTitle: String { name }
    public var menuTitle: String { name }
    public var detail: String? {
        "× \(scaleFactor.cleanWithoutRounding)"
    }
    public static var `default`: ActivityLevel { .lightlyActive }
}

extension ActivityLevel {
    var description: String {
        switch self {
        case .sedentary:
            "You work a desk job with little or no exercise."
        case .lightlyActive:
            "You work a job with light physical demands, or you work a desk job and perform light exercise (at the level of a brisk walk) for 30 minutes per day, 3-5 times per week."
        case .moderatelyActive:
            "You work a moderately physically demanding job, such as a construction worker, or you work a desk job and engage in moderate exercise for 1 hour per day, 3-5 times per week."
        case .active:
            "You work a consistently physically demanding job, such as an agricultural worker, or you work a desk job and engage in intense exercise for 1 hour per day or moderate exercise for 2 hours per day, 5-7 times per week."
        case .veryActive:
            "You work an extremely physically demanding job, such as a professional athlete, competitive cyclist, or fitness professional, or you engage in intense exercise for at least 2 hours per day."
        }
    }
}
