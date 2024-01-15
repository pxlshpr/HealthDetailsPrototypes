import SwiftUI

import PrepShared

@Observable class SettingsProvider {
    
    var settings: Settings

    static var shared: SettingsProvider {
        SettingsProvider(settings: fetchSettingsFromDocuments())
    }
    
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
    
    func isHealthKitSyncing(_ healthDetail: HealthDetail) -> Bool {
        settings.isHealthKitSyncing(healthDetail)
    }
    
    func setHealthKitSyncing(for healthDetail: HealthDetail, to isOn: Bool) {
        settings.setHealthKitSyncing(for: healthDetail, to: isOn)
        save()
    }
    
    var heightIsHealthKitSynced: Bool {
        get { settings.isHealthKitSyncing(.height) }
        set { setHealthKitSyncing(for: .height, to: newValue) }
    }

    var weightIsHealthKitSynced: Bool {
        get { settings.isHealthKitSyncing(.weight) }
        set { setHealthKitSyncing(for: .weight, to: newValue) }
    }

    var leanBodyMassIsHealthKitSynced: Bool {
        get { settings.isHealthKitSyncing(.leanBodyMass) }
        set { setHealthKitSyncing(for: .leanBodyMass, to: newValue) }
    }

//    var fatPercentageIsHealthKitSynced: Bool {
//        get { settings.isHealthKitSyncing(.fatPercentage) }
//        set { settings.setHealthKitSyncing(for: .fatPercentage, to: newValue) }
//    }

    var energyUnit: EnergyUnit {
        settings.energyUnit
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

extension SettingsProvider {
    func energyString(_ kcal: Double) -> String {
        "\(EnergyUnit.kcal.convert(kcal, to: energyUnit).formattedEnergy) \(energyUnit.abbreviation)"
    }
    
    func bodyMassString(_ kg: Double) -> String {
        "\(BodyMassUnit.kg.convert(kg, to: bodyMassUnit).formattedEnergy) \(bodyMassUnit.abbreviation)"
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
