import Foundation
import PrepShared

struct WeightChange: Hashable, Codable {

    var kg: Double?
    var type: WeightChangeType = .weights
    var points: Points? = nil
    
    struct Points: Hashable, Codable {
        var start: WeightChangePoint
        var end: WeightChangePoint
        
        init(date: Date, interval: HealthInterval) {
            self.end = .init(date: date)
            self.start = .init(date: interval.startDate(with: date))
        }
        
        var weightChangeInKg: Double? {
            guard let endKg = end.kg, let startKg = start.kg else { return nil }
            return endKg - startKg
        }
    }
    
    var isEmpty: Bool {
        kg == nil
    }

    var energyEquivalentInKcal: Double? {
        guard let kg else { return nil }
//        454 g : 3500 kcal
//        delta : x kcal
        return (3500 * kg) / BodyMassUnit.lb.convert(1, to: .kg)
    }
    
    func energyEquivalent(in energyUnit: EnergyUnit) -> Double? {
        guard let kcal = energyEquivalentInKcal else { return nil }
        return EnergyUnit.kcal.convert(kcal, to: energyUnit)
    }
}
