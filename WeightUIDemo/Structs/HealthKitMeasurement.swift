import Foundation
import HealthKit

let HealthKitBundleIdentifier: String = "com.ahmdrghb.WeightUIDemo"
let HealthKitMetadataIDKey: String = "PrepID"

extension HKQuantitySample {
    var date: Date {
        startDate
    }
    
    var prepID: String? {
        metadata?[HealthKitMetadataIDKey] as? String
    }
}

extension Array where Element == HKQuantitySample {
//    var averageValue: Double? {
//        map{ $0.value }.average
//    }
    
    var notOurs: [HKQuantitySample] {
        filter { $0.sourceRevision.source.bundleIdentifier != HealthKitBundleIdentifier }
    }
    
    var ours: [HKQuantitySample] {
        filter { $0.sourceRevision.source.bundleIdentifier == HealthKitBundleIdentifier }
    }
    
    func notPresent(in measurements: [any Measurable]) -> [HKQuantitySample] {
        filter {
            /// If there's no `prepID`, consider it not to be present
            guard let prepID = $0.prepID else { return true }
            return !measurements.contains(where: { $0.id.uuidString == prepID })
        }
    }
}
