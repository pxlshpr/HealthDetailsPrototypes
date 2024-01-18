import SwiftUI
import HealthKit

extension Array where Element: HKQuantitySample {
    func removingSamplesWithTheSameValueAtTheSameTime(with unit: HKUnit) -> [HKQuantitySample] {
        var array: [HKQuantitySample] = []

        for sample in self {
            /// If the array already contains a value at the same *minute* as this element with the same value (to 1 decimal place)
            if let index = array.firstIndex(where: { $0.hasSameValueAndTime(as: sample, with: unit) }) {
                /// Then replace it with this, if the UUID alphabetically precedes the existing one's UUID
                if sample.shouldBePicked(insteadOf: array[index]) {
                    array[index] = sample
                }
                /// Otherwise ignore it
            } else {
                array.append(sample)
            }
        }
        return array
    }
}

extension HKQuantitySample {
    func hasSameValueAndTime(as sample: HKQuantitySample, with unit: HKUnit) -> Bool {
        quantity.doubleValue(for: unit).rounded(toPlaces: 1) == sample.quantity.doubleValue(for: unit).rounded(toPlaces: 1)
        && startDate.equalsIgnoringSeconds(sample.startDate)
    }
    
    func shouldBePicked(insteadOf sample: HKQuantitySample) -> Bool {
        uuid.uuidString < sample.uuid.uuidString
    }
}
