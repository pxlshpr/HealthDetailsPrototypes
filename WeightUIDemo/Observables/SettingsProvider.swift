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

    func saveEnergyUnit(_ energyUnit: EnergyUnit) {
        settings.energyUnit = energyUnit
        save()
    }

    func saveBodyMassUnit(_ bodyMassUnit: BodyMassUnit) {
        settings.bodyMassUnit = bodyMassUnit
        save()
    }
}

extension SettingsProvider {
    
    var heightIsHealthKitSynced: Bool {
        get { settings.isHealthKitSyncing(.height) }
        set { settings.setHealthKitSyncing(for: .height, to: newValue) }
    }

    var weightIsHealthKitSynced: Bool {
        get { settings.isHealthKitSyncing(.weight) }
        set { settings.setHealthKitSyncing(for: .weight, to: newValue) }
    }

    var leanBodyMassIsHealthKitSynced: Bool {
        get { settings.isHealthKitSyncing(.leanBodyMass) }
        set { settings.setHealthKitSyncing(for: .leanBodyMass, to: newValue) }
    }

//    var fatPercentageIsHealthKitSynced: Bool {
//        get { settings.isHealthKitSyncing(.fatPercentage) }
//        set { settings.setHealthKitSyncing(for: .fatPercentage, to: newValue) }
//    }

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

extension SettingsProvider {
    func unit(for healthUnit: any HealthUnit.Type) -> (any HealthUnit)? {
        if healthUnit is BodyMassUnit.Type {
            bodyMassUnit
        } else if healthUnit is HeightUnit.Type {
            heightUnit
        } else {
            nil
        }
    }
    
    func unitString(for measurementType: MeasurementType) -> String {
        switch measurementType {
        case .height:
            heightUnit.abbreviation
        case .weight, .leanBodyMass:
            bodyMassUnit.abbreviation
        case .fatPercentage:
            "%"
        case .energy:
            energyUnit.abbreviation
        }
    }
    
    func secondUnitString(for measurementType: MeasurementType) -> String? {
        switch measurementType {
        case .height:
            heightUnit.secondaryUnit
        case .weight, .leanBodyMass:
            bodyMassUnit.secondaryUnit
        case .fatPercentage:
            nil
        case .energy:
            nil
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
