import Foundation

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
    var description: String {
        switch self {
        case .katchMcardle:
            "Uses your lean body mass, similar to the Cunningham equation. It is considered more accurate for individuals with low percentages of body fat or high amounts of muscle mass"
        case .henryOxford:
            "Uses your weight, age and biological sex. It is among the 'newer' equations. It is thought that it also represents all ethnicities, as it is based on 10,502 men and women from both developed and developing countries."
        case .mifflinStJeor:
            "Uses your height, weight, age, and biological sex. The second revision/simplification of the Harris-Benedict equation that was carried out 71 years later, based on a sample that was wider in age and larger by 259 individuals."
        case .schofield:
            "Uses your weight, age and biological sex. The original dataset is made up of predominantly Italian subjects, a large percentage of whom were male. Growing evidence suggests that this formula has the tendency to overestimate per kilogram body weight amongst other ethnicities, particularly individuals outside of Europe."
        case .cunningham:
            "Uses your lean body mass, similar to the Katch-McArdle equation. It can be more accurate for individuals with high percentages of body fat."
        case .rozaShizgal:
            "Uses your height, weight, age, and biological sex. The first revision of the Harris-Benedict equation that was carried out 65 years later, based on a sample that was older, larger by 98 people, and almost equally divided between the sexes."
        case .harrisBenedict:
            "Uses your height, weight, age, and biological sex. The equation was published more than 100 years ago and remains still the most frequently used in daily practice. This equation was based on 239 subjects (136 men and 108 women), aged 16–63 years."
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
