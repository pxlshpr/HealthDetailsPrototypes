import Foundation
import PrepShared

public enum RestingEnergyEquation: Int16, Hashable, Codable, CaseIterable {
    case katchMcardle = 1
    case henryOxford
    case mifflinStJeor
    case schofield
    case cunningham
    case rozaShizgal
    case harrisBenedict
}

extension RestingEnergyEquation: Pickable {
    public var pickedTitle: String { name }
    public var menuTitle: String { name }
    public static var `default`: RestingEnergyEquation { .katchMcardle }
    public var detail: String? { year }
}

public extension RestingEnergyEquation {
    var name: String {
        switch self {
        case .schofield:        "Schofield"
        case .henryOxford:      "Henry Oxford"
        case .harrisBenedict:   "Harris-Benedict"
        case .cunningham:       "Cunningham"
        case .rozaShizgal:      "Roza-Shizgal"
        case .mifflinStJeor:    "Mifflin-St. Jeor"
        case .katchMcardle:     "Katch-McArdle"
        }
    }
    
    var year: String {
        switch self {
        case .schofield:        "1985"
        case .henryOxford:      "2005"
        case .harrisBenedict:   "1919"
        case .cunningham:       "1980"
        case .rozaShizgal:      "1984"
        case .mifflinStJeor:    "1990"
        case .katchMcardle:     "1996"
        }
    }
}

/// https://www.nutritics.com/en/resources/blog/a-guide-on-predictive-equations-for-energy-calculation
/// https://www.mdpi.com/2218-1989/13/2/189 (lots more info)

extension RestingEnergyEquation {
    
    var requiredHealthDetails: [HealthDetail] {
        switch self {
        case .katchMcardle:
            [.leanBodyMass]
        case .cunningham:
            [.leanBodyMass]
        case .rozaShizgal:
            [.height, .weight, .age, .sex]
        case .schofield:
            [.weight, .age, .sex]
        case .mifflinStJeor:
            [.height, .weight, .age, .sex]
        case .harrisBenedict:
            [.height, .weight, .age, .sex]
        case .henryOxford:
            [.weight, .age, .sex]
        }
    }
}
extension RestingEnergyEquation {
    
    var variablesDescription: String {
        switch self {
        case .katchMcardle:
            "Lean body mass"
        case .cunningham:
            "Lean body mass"
        case .rozaShizgal:
            "Height, weight, age, and biological sex"
        case .schofield:
            "Weight, age and biological sex"
        case .mifflinStJeor:
            "Height, weight, age, and biological sex"
        case .harrisBenedict:
            "Height, weight, age, and biological sex"
        case .henryOxford:
            "Weight, age and biological sex"
        }
    }

    var description: String {
        switch self {
        case .katchMcardle:
            "Similar to the Cunningham equation, but considered to be more accurate for individuals with low percentages of body fat or high amounts of muscle mass."
        case .cunningham:
            "Similar to the Katch-McArdle equation, but considered to be more accurate for individuals with high percentages of body fat."
        case .rozaShizgal:
            "The first revision of the Harris-Benedict equation that was carried out 65 years later, based on a dataset that was older, larger by 98 people, and almost equally divided between the sexes."
        case .schofield:
            "This is the equation used by the WHO.\n\nThe dataset is made up of predominantly Italian subjects, a large percentage of whom were male.\n\nGrowing evidence suggests that this formula has the tendency to overestimate per kilogram body weight amongst other ethnicities, particularly individuals outside of Europe."
        case .mifflinStJeor:
            "The second revision/simplification of the Harris-Benedict equation that was carried out 71 years later, based on a sample that was wider in age and larger by 259 individuals."
        case .harrisBenedict:
            "The Harris–Benedict equation was published more than 100 years ago, without the help of modern computers. It remains still the most frequently used in daily practice.\n\nThis equation was based on 239 subjects (136 men and 108 women), aged 16–63 years."
        case .henryOxford:
            "Among the 'newer' equations, the Henry-Oxford equation is considered to represent all ethnicities, as it is based on 10,502 men and women from both developed and developing countries."
        }
    }
    
//    var params: [HealthType] {
//        switch self {
//        case .katchMcardle, .cunningham:
//            [.leanBodyMass]
//        case .henryOxford, .schofield:
//            [.sex, .age, .weight]
//        case .mifflinStJeor, .rozaShizgal, .harrisBenedict:
//            [.sex, .age, .weight, .height]
//        }
//    }

}

extension RestingEnergyEquation {
    static var inOrderOfYear: [RestingEnergyEquation] {
//        [.henryOxford, .katchMcardle, .mifflinStJeor, .schofield, .rozaShizgal, .cunningham, .harrisBenedict]
        [.harrisBenedict, .cunningham, .rozaShizgal, .schofield, .mifflinStJeor, .katchMcardle, .henryOxford]
    }
}
