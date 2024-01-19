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
    
    var variables: Variables {
        if requiredHealthDetails == [.leanBodyMass] {
            .leanBodyMass(variablesExplanation)
        } else {
            .required(requiredHealthDetails, variablesExplanation)
        }
    }
    
    var requiredHealthDetails: [HealthDetail] {
        switch self {
        case .katchMcardle:
            [.leanBodyMass]
        case .cunningham:
            [.leanBodyMass]
        case .rozaShizgal:
            [.height, .weight, .age, .biologicalSex]
        case .schofield:
            [.weight, .age, .biologicalSex]
        case .mifflinStJeor:
            [.height, .weight, .age, .biologicalSex]
        case .harrisBenedict:
            [.height, .weight, .age, .biologicalSex]
        case .henryOxford:
            [.weight, .age, .biologicalSex]
        }
    }
}
extension RestingEnergyEquation {
    
    var variablesExplanation: String {
        switch self {
        case .katchMcardle, .cunningham:
            return "Your Lean Body Mass is required for the \(name) equation. You could alternatively provide your Fat Percentage and Weight."
        default:
            let conjunction = requiredHealthDetails.count == 1 ? "is" : "are"
            return "Your \(variablesDescription) \(conjunction) required for the \(name) equation."
        }
    }
    
    var variablesDescription: String {
        switch self {
        case .katchMcardle, .cunningham:
            ""
        case .rozaShizgal, .mifflinStJeor, .harrisBenedict:
            "Age, Biological Sex, Weight and Height"
        case .schofield, .henryOxford:
            "Age, Biological Sex and Weight"
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


extension HealthProvider {
    func calculateRestingEnergyInKcal(
        using equation: RestingEnergyEquation
    ) async -> Double? {
        await equation.calculate(
            ageInYears: ageInYears,
            biologicalSex: biologicalSex,
            weightInKg: healthDetails.currentOrLatestWeightInKg,
            leanBodyMassInKg: healthDetails.currentOrLatestLeanBodyMassInKg,
            fatPercentage: healthDetails.currentOrLatestFatPercentage,
            heightInCm: healthDetails.currentOrLatestHeightInCm,
            preferLeanBodyMass: healthDetails.maintenance.estimate.restingEnergy.preferLeanBodyMass,
            energyUnit: .kcal
        )
    }
    
    func calculateFatPercentageInPercent(
        using equation: LeanBodyMassAndFatPercentageEquation
    ) async -> Double? {
        await equation.calculateFatPercentageInPercent(
            biologicalSex: biologicalSex,
            weightInKg: healthDetails.currentOrLatestWeightInKg,
            heightInCm: healthDetails.currentOrLatestHeightInCm,
            ageInYears: ageInYears
        )
    }
    
    func calculateLeanBodyMassInKg(
        using equation: LeanBodyMassAndFatPercentageEquation
    ) async -> Double? {
        await equation.calculateLeanBodyMassInKg(
            biologicalSex: biologicalSex,
            weightInKg: healthDetails.currentOrLatestWeightInKg,
            heightInCm: healthDetails.currentOrLatestHeightInCm,
            ageInYears: ageInYears
        )
    }

}
extension RestingEnergyEquation {
    
    func calculate(
        ageInYears: Int?,
        biologicalSex: BiologicalSex,
        weightInKg: Double?,
        leanBodyMassInKg: Double?,
        fatPercentage: Double?,
        heightInCm: Double?,
        preferLeanBodyMass: Bool,
        energyUnit: EnergyUnit
    ) async -> Double? {
        
        var chosenLeanBodyMassInKg: Double? {
            switch (leanBodyMassInKg, fatPercentage, weightInKg) {
            case (.some(let lbm), .some(let fatP), .some(let weight)):
                /// If we have all 3, pick whatever the user prefers
                if preferLeanBodyMass {
                    lbm
                } else {
                    calculateLeanBodyMass(
                        fatPercentage: fatP,
                        weightInKg: weight
                    )
                }
                
            case (.some(let lbm), .none, .none),
                (.some(let lbm), .none, .some),
                (.some(let lbm), .some, .none):
                /// If we have the lean body mass and not both fat percentage and weight, pick lean body mass regardless of what the user prefers
                lbm
            case (.none, .some(let fatP), .some(let weight)):
                /// If we have fat percentage and weight, and not lean body mass, pick fat percentage and weight regardless of what the user prefers
                calculateLeanBodyMass(fatPercentage: fatP, weightInKg: weight)
            default:
                nil
            }
        }
        
        var kcal: Double? {
            switch self {
                
            case .katchMcardle:
                guard let lbm = chosenLeanBodyMassInKg else { return nil }
                return 370 + (21.6 * lbm)

            case .cunningham:
                guard let lbm = chosenLeanBodyMassInKg else { return nil }
                return 500 + (22.0 * lbm)
                
            case .henryOxford:
                guard let ageInYears, let weightInKg, biologicalSex != .notSet else { return nil }
                let ageGroup = AgeGroup(ageInYears)
                guard
                    let a = OxfordCoefficients.a(biologicalSex, ageGroup),
                    let c = OxfordCoefficients.c(biologicalSex, ageGroup)
                else { return nil }
                return (a * weightInKg) + c
                
            case .schofield:
                guard let ageInYears, let weightInKg, biologicalSex != .notSet else { return nil }
                let ageGroup = AgeGroup(ageInYears)
                guard
                    let a = SchofieldCoefficients.a(biologicalSex, ageGroup),
                    let c = SchofieldCoefficients.c(biologicalSex, ageGroup)
                else { return nil }
                return (a * weightInKg) + c
                
            case .mifflinStJeor:
                guard let ageInYears, let weightInKg, let heightInCm else { return nil }
                return switch biologicalSex {
                case .female:   (9.99 * weightInKg) + (6.25 * heightInCm) - (4.92 * Double(ageInYears)) - 161
                case .male:     (9.99 * weightInKg) + (6.25 * heightInCm) - (4.92 * Double(ageInYears)) + 5
                case .notSet:   nil
                }
                
            case .rozaShizgal:
                guard let ageInYears, let weightInKg, let heightInCm else { return nil }
                return switch biologicalSex {
                case .female:   447.593 + (9.247 * weightInKg) + (3.098 * heightInCm) - (4.33 * Double(ageInYears))
                case .male:     88.362 + (13.397 * weightInKg) + (4.799 * heightInCm) - (5.677 * Double(ageInYears))
                case .notSet:   nil
                }
                
            case .harrisBenedict:
                guard let ageInYears, let weightInKg, let heightInCm else { return nil }
                return switch biologicalSex {
                case .female:   655.0955 + (9.5634 * weightInKg) + (1.8496 * heightInCm) - (4.6756 * Double(ageInYears))
                case .male:     66.4730 + (13.7516 * weightInKg) + (5.0033 * heightInCm) - (6.7550 * Double(ageInYears))
                case .notSet:   nil
                }
            }
        }
        
        guard let kcal else { return nil }
        let value = EnergyUnit.kcal.convert(kcal, to: energyUnit)
        return max(value, 0)
    }
}

import Foundation

public enum AgeGroup {
    case zeroToTwo
    case threeToNine
    case tenToSeventeen
    case eighteenToTwentyNine
    case thirtyToFiftyNine
    case sixtyAndOver
    
    public init(_ ageInYears: Int) {
        switch ageInYears {
        case 0..<3:
            self = .zeroToTwo
        case 3..<9:
            self = .threeToNine
        case 10..<17:
            self = .tenToSeventeen
        case 18..<29:
            self = .eighteenToTwentyNine
        case 30..<59:
            self = .thirtyToFiftyNine
        default:
            self = .sixtyAndOver
        }
    }
}


import Foundation

struct OxfordCoefficients {
    
    static func a(_ biologicalSex: BiologicalSex, _ ageGroup: AgeGroup) -> Double? {
        switch biologicalSex {
        case .female:
            switch ageGroup {
            case .zeroToTwo:            58.9
            case .threeToNine:          20.1
            case .tenToSeventeen:       11.1
            case .eighteenToTwentyNine: 13.1
            case .thirtyToFiftyNine:    9.74
            case .sixtyAndOver:         10.1
            }
        case .male:
            switch ageGroup {
            case .zeroToTwo:            61.0
            case .threeToNine:          23.3
            case .tenToSeventeen:       18.4
            case .eighteenToTwentyNine: 16.0
            case .thirtyToFiftyNine:    14.2
            case .sixtyAndOver:         13.5
            }
        case .notSet: nil
        }
    }
    
    static func c(_ biologicalSex: BiologicalSex, _ ageGroup: AgeGroup) -> Double? {
        switch biologicalSex {
        case .female:
            switch ageGroup {
            case .zeroToTwo:            -23.1
            case .threeToNine:          507
            case .tenToSeventeen:       761
            case .eighteenToTwentyNine: 558
            case .thirtyToFiftyNine:    694
            case .sixtyAndOver:         569
            }
        case .male:
            switch ageGroup {
            case .zeroToTwo:            -33.7
            case .threeToNine:          514
            case .tenToSeventeen:       581
            case .eighteenToTwentyNine: 545
            case .thirtyToFiftyNine:    593
            case .sixtyAndOver:         514
            }
        case .notSet: nil
        }
    }
}

import Foundation

struct SchofieldCoefficients {
    static func a(_ biologicalSex: BiologicalSex, _ ageGroup: AgeGroup) -> Double? {
        switch biologicalSex {
        case .female:
            switch ageGroup {
            case .zeroToTwo:            58.317
            case .threeToNine:          20.315
            case .tenToSeventeen:       13.384
            case .eighteenToTwentyNine: 14.818
            case .thirtyToFiftyNine:    8.126
            case .sixtyAndOver:         9.082
            }
        case .male:
            switch ageGroup {
            case .zeroToTwo:            59.512
            case .threeToNine:          22.706
            case .tenToSeventeen:       17.686
            case .eighteenToTwentyNine: 15.057
            case .thirtyToFiftyNine:    11.472
            case .sixtyAndOver:         11.711
            }
        case .notSet: nil
        }
    }
    
    static func c(_ biologicalSex: BiologicalSex, _ ageGroup: AgeGroup) -> Double? {
        switch biologicalSex {
        case .female:
            switch ageGroup {
            case .zeroToTwo:            -31.1
            case .threeToNine:          485.9
            case .tenToSeventeen:       692.6
            case .eighteenToTwentyNine: 486.6
            case .thirtyToFiftyNine:    845.6
            case .sixtyAndOver:         658.5
            }
        case .male:
            switch ageGroup {
            case .zeroToTwo:            -30.4
            case .threeToNine:          504.3
            case .tenToSeventeen:       658.2
            case .eighteenToTwentyNine: 692.2
            case .thirtyToFiftyNine:    873.1
            case .sixtyAndOver:         587.7
            }
        case .notSet: nil
        }
    }
}
