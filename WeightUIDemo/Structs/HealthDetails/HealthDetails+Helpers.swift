import Foundation

extension HealthDetails {
    
//    var missingNonTemporalHealthDetails: [HealthDetail] {
//        HealthDetail.allNonTemporalHealthDetails.filter { !hasSet($0) }
//    }

    func data(for healthDetail: HealthDetail) -> Any? {
        if healthDetail == .maintenance {
            var maintenance = maintenance
//            maintenance.isBroughtForward = false
            return maintenance
        }
        return switch healthDetail {
//        case .maintenance:      maintenance
        case .age:              dateOfBirthComponents
        case .biologicalSex:    biologicalSex
        case .weight:           weight
        case .leanBodyMass:     leanBodyMass
        case .height:           height
        case .preganancyStatus: pregnancyStatus
        case .smokingStatus:    smokingStatus
        case .fatPercentage:    fatPercentage
        default:                nil
        }
    }
    
    func hasSet(_ healthDetail: HealthDetail) -> Bool {
        switch healthDetail {
        case .maintenance:      maintenance.kcal != nil
        case .age:              ageInYears != nil
        case .biologicalSex:    biologicalSex != .notSet
        case .weight:           weight.weightInKg != nil
        case .leanBodyMass:     leanBodyMass.leanBodyMassInKg != nil
        case .fatPercentage:    fatPercentage.fatPercentage != nil
        case .height:           height.heightInCm != nil
        case .preganancyStatus: pregnancyStatus != .notSet
        case .smokingStatus:    smokingStatus != .notSet
        }
    }

//    func secondaryValueString(
//        for healthDetail: HealthDetail,
//        _ settingsProvider: SettingsProvider
//    ) -> String? {
//        switch healthDetail {
//        case .leanBodyMass:
//            leanBodyMass.secondaryValueString()
//        default:
//            nil
//        }
//    }

    func valueString(
        for healthDetail: HealthDetail,
        _ settingsProvider: SettingsProvider
    ) -> String {
        switch healthDetail {
        case .age:
            if let ageInYears {
                "\(ageInYears)"
            } else {
                NotSetString
            }
        case .biologicalSex:
            biologicalSex.name
        case .weight:
            weight.valueString(in: settingsProvider.bodyMassUnit)
        case .leanBodyMass:
            leanBodyMass.valueString(in: settingsProvider.bodyMassUnit)
        case .fatPercentage:
            fatPercentage.valueString
        case .height:
            height.valueString(in: settingsProvider.heightUnit)
        case .preganancyStatus:
            pregnancyStatus.name
        case .smokingStatus:
            smokingStatus.name
        case .maintenance:
            maintenance.valueString(in: settingsProvider.energyUnit)
        }
    }
}

extension HealthDetails {
    func containsChangesInSyncableMeasurements(from other: HealthDetails) -> Bool {
        weight != other.weight
        || height != other.height
        || leanBodyMass != other.leanBodyMass
        || fatPercentage != other.fatPercentage
    }
}
