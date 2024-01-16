import Foundation
import PrepShared

extension Double {
    
    func convertEnergy(from fromUnit: EnergyUnit, to toUnit: EnergyUnit) -> Double {
        fromUnit.convert(self, to: toUnit)
    }
    
    func valueString(convertedFrom fromUnit: BodyMassUnit, to unit: BodyMassUnit) -> String {
        let converted = fromUnit.convert(self, to: unit)
        let double = unit.doubleComponent(of: converted)
        if let int = unit.intComponent(of: converted), let intUnit = unit.intUnitString {
            return "\(int) \(intUnit) \(double.cleanHealth) \(unit.doubleUnitString)"
        } else {
            return "\(double.cleanHealth) \(unit.doubleUnitString)"
        }
    }
}

extension Optional where Wrapped == Double {

    func convertBodyMass(from fromUnit: BodyMassUnit, to toUnit: BodyMassUnit) -> Double? {
        guard let self else { return nil }
        return fromUnit.convert(self, to: toUnit)
    }

    func convertEnergy(from fromUnit: EnergyUnit, to toUnit: EnergyUnit) -> Double? {
        guard let self else { return nil }
        return fromUnit.convert(self, to: toUnit)
    }

    func valueString(convertedFrom fromUnit: EnergyUnit, to unit: EnergyUnit) -> String {
        guard let self else { return NotSetString }
        let converted = fromUnit.convert(self, to: unit)
        return "\(converted.formattedEnergy) \(unit.doubleUnitString)"
    }
    
    func valueString(convertedFrom fromUnit: BodyMassUnit, to unit: BodyMassUnit) -> String {
        guard let self else { return NotSetString }
        return self.valueString(convertedFrom: fromUnit, to: unit)
    }
    
    func valueString(convertedFrom fromUnit: HeightUnit, to unit: HeightUnit) -> String {
        guard let self else { return NotSetString }
        let converted = fromUnit.convert(self, to: unit)
        let double = unit.doubleComponent(of: converted)
        if let int = unit.intComponent(of: converted), let intUnit = unit.intUnitString {
            return "\(int) \(intUnit) \(double.cleanHealth) \(unit.doubleUnitString)"
        } else {
            return "\(double.cleanHealth) \(unit.doubleUnitString)"
        }
    }
}
