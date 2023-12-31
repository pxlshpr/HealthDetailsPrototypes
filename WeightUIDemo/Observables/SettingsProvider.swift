import SwiftUI

import PrepShared

@Observable class SettingsProvider {
    
    var settings: Settings

    public init(
        settings: Settings = Settings()
    ) {
        self.settings = settings
    }
}

extension SettingsProvider {
    
    func saveHeightUnit(_ heightUnit: HeightUnit) {
        settings.heightUnit = heightUnit
        save()
    }
}

extension SettingsProvider {
    
    var energyUnit: EnergyUnit {
        get { settings.energyUnit }
        set {
            settings.energyUnit = newValue
        }
    }

    var metricType: GoalMetricType {
        get { settings.metricType }
        set {
            withAnimation {
                settings.metricType = newValue
            }
        }
    }

    var expandedMicroGroups: [MicroGroup] {
        get { settings.expandedMicroGroups }
        set {
            withAnimation {
                settings.expandedMicroGroups = newValue
            }
        }
    }
    
    //MARK: Units
    
    var heightUnit: HeightUnit {
        get { settings.heightUnit }
        set {
            settings.heightUnit = newValue
        }
    }
    
    var bodyMassUnit: BodyMassUnit {
        get { settings.bodyMassUnit }
        set {
            settings.bodyMassUnit = newValue
        }
    }
}

//import HealthKit
//
//public extension SettingsStore {
//    
//    static func unit(for type: QuantityType) -> HKUnit {
//        switch type {
//        case .weight, .leanBodyMass:
//            shared.settings.bodyMassUnit.healthKitUnit
//        case .height:
//            shared.settings.heightUnit.healthKitUnit
//        case .restingEnergy, .activeEnergy:
//            shared.settings.energyUnit.healthKitUnit
//        }
//    }
//}

//TODO: Replace this with actual backend manipulation in Prep
extension SettingsProvider {
    func save() {
        saveSettingsInDocuments(settings)
    }
}
