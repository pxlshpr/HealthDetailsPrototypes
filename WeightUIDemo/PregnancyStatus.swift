public enum PregnancyStatus: Int16, Codable {
    case notPregnantOrLactating
    case pregnant
    case lactating
    case notSet
}

public extension PregnancyStatus {
    var name: String {
        switch self {
        case .notPregnantOrLactating:   "None"
        case .pregnant:                 "Pregnant"
        case .lactating:                "Breastfeeding"
        case .notSet:                   "Not Set"
        }
    }
}

extension PregnancyStatus: Pickable {
    public var pickedTitle: String { name }
    public var menuTitle: String { name }
    public static var `default`: PregnancyStatus { .notPregnantOrLactating }
    public static var noneOption: PregnancyStatus? { .notSet }
}

