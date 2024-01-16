import Foundation

enum LeanBodyMassAndFatPercentageEquation: Int, Identifiable, Codable, CaseIterable {
    case boer = 1
    case james
    case hume
    
    case bmi
    
    var id: Int {
        rawValue
    }
}

extension LeanBodyMassAndFatPercentageEquation {
    
    var requiredHealthDetails: [HealthDetail] {
        switch self {
        case .boer, .james, .hume:
            [.height, .weight, .biologicalSex]
        case .bmi:
            [.height, .weight, .biologicalSex, .age]
        }
    }
    
    var year: String {
        switch self {
        case .boer:     "1984"
        case .james:    "1976"
        case .hume:     "1966"
        case .bmi:      "1991"
        }
    }
    
    var name: String {
        switch self {
        case .boer:     "Boer"
        case .james:    "James"
        case .hume:     "Hume"
        case .bmi:      "BMI"
        }
    }

    func calculateFatPercentageInPercent(
        biologicalSex: BiologicalSex,
        weightInKg: Double?,
        heightInCm: Double?,
        ageInYears: Int?
    ) async -> Double? {
        
        guard calculatesFatPercentage else {
            guard let weightInKg, let leanBodyMassInKg = await calculateLeanBodyMassInKg(
                biologicalSex: biologicalSex,
                weightInKg: weightInKg,
                heightInCm: heightInCm,
                ageInYears: ageInYears
            ) else { return nil }
            return calculateFatPercentage(
                leanBodyMassInKg: leanBodyMassInKg,
                weightInKg: weightInKg
            )
        }

        guard
            let weightInKg, let heightInCm,
                weightInKg > 0, heightInCm > 0,
                biologicalSex != .notSet,
            let ageInYears
        else { return nil }
        
        let heightInMeters = heightInCm / 100.0
        let bmi = weightInKg / pow(heightInMeters, 2)

        let percent: Double? = switch biologicalSex {
        case .female:
            switch self {
            case .bmi:  (1.20 * bmi) + (0.23 * Double(ageInYears)) - 5.4
            default:    nil
            }
        case .male:
            switch self {
            case .bmi:  (1.20 * bmi) + (0.23 * Double(ageInYears)) - 16.2
            default:    nil
            }
        default:        nil
        }
        
        guard let percent else { return nil }
        return max(percent, 0)
    }
    
    var calculatesLeanBodyMass: Bool {
        switch self {
        case .boer, .james, .hume:  true
        default:                    false
        }
    }
    
    var calculatesFatPercentage: Bool {
        !calculatesLeanBodyMass
    }
    
    /**
     Equations taken from: https://www.calculator.net/lean-body-mass-calculator.html)
     BMI equation: https://www.tgfitness.com/body-fat-percentage-calculator/#:~:text=The%20formula%20uses%20a%20person%27s,their%20height%20in%20meters%20squared.
     */
    func calculateLeanBodyMassInKg(
        biologicalSex: BiologicalSex,
        weightInKg weight: Double?,
        heightInCm height: Double?,
        ageInYears age: Int?
    ) async -> Double? {
        
        guard calculatesLeanBodyMass else {
            guard let weight, let percent = await calculateFatPercentageInPercent(
                biologicalSex: biologicalSex,
                weightInKg: weight,
                heightInCm: height,
                ageInYears: age
            ) else { return nil }
            return calculateLeanBodyMass(
                fatPercentage: percent,
                weightInKg: weight
            )
        }
        
        guard
            let weight, let height,
                weight > 0, height > 0,
                biologicalSex != .notSet
        else { return nil }
        
        let kg: Double? = switch biologicalSex {
        case .female:
            /// female
            switch self {
            case .boer:     (0.252 * weight) + (0.473 * height) - 48.3
            case .james:    (1.07 * weight) - (148.0 * pow((weight/height), 2.0))
            case .hume:     (0.29569 * weight) + (0.41813 * height) - 43.2933
            default:        nil
            }
        case .male:
            /// male
            switch self {
            case .boer:     (0.407 * weight) + (0.267 * height) - 19.2
            case .james:    (1.1 * weight) - (128.0 * pow((weight/height), 2.0))
            case .hume:     (0.32810 * weight) + (0.33929 * height) - 29.5336
            default:        nil
            }
        default:            nil
        }
        
        guard let kg else { return nil }
        return max(kg, 0)
    }
}

func calculateFatPercentage(
    leanBodyMassInKg lbm: Double,
    weightInKg weight: Double
) -> Double {
    ((max(0, (weight - lbm)) / weight) * 100)
//        .rounded(toPlaces: 1)
}

func calculateLeanBodyMass(
    fatPercentage percent: Double,
    weightInKg weight: Double
) -> Double {
    weight - ((percent / 100.0) * weight)
}
