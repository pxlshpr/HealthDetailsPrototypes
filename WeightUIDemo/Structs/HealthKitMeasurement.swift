import Foundation

public struct HealthKitMeasurement: Hashable, Codable {
    public var id: UUID
    public var prepID: String?
    public var value: Double
    public var date: Date
    public var sourceName: String
    public var sourceBundleIdentifier: String
    
    public init(
        id: UUID,
        prepID: String?,
        value: Double,
        date: Date,
        sourceName: String,
        sourceBundleIdentifier: String
    ) {
        self.id = id
        self.prepID = prepID
        self.value = value
        self.date = date
        self.sourceName = sourceName
        self.sourceBundleIdentifier = sourceBundleIdentifier
    }
    
    
//    init?(value: Double?)  {
//        guard let value else {
//            return nil
//        }
//        self.value = value
//        self.date = nil
//    }
}

extension Array where Element == HealthDetails.Weight {
    var averageValue: Double? {
        compactMap{ $0.weightInKg }.average
    }
}

extension Array where Element == HealthKitMeasurement {
    var averageValue: Double? {
        map{ $0.value }.average
    }
    
    var notOurs: [HealthKitMeasurement] {
        filter { $0.sourceBundleIdentifier != HealthKitBundleIdentifier }
    }
    
    var ours: [HealthKitMeasurement] {
        filter { $0.sourceBundleIdentifier == HealthKitBundleIdentifier }
    }
    
    func notPresent(in measurements: [any Measurable]) -> [HealthKitMeasurement] {
        filter {
            /// If there's no `prepID`, consider it not to be present
            guard let prepID = $0.prepID else { return true }
            return !measurements.contains(where: { $0.id.uuidString == prepID })
        }
    }
}

let HealthKitBundleIdentifier: String = "com.xxx"
let HealthKitMetadataIDKey: String = "PrepID"

import HealthKit

extension HKQuantitySample {
    func asHealthKitMeasurement(in healthKitUnit: HKUnit) -> HealthKitMeasurement {
        let quantity = quantity.doubleValue(for: healthKitUnit)
        let date = startDate
        return HealthKitMeasurement(
            id: uuid,
            prepID: metadata?[HealthKitMetadataIDKey] as? String,
            value: quantity,
            date: date,
            sourceName: sourceRevision.source.name,
            sourceBundleIdentifier: sourceRevision.source.bundleIdentifier
        )
    }
}

public extension Array where Element == HealthKitMeasurement {
    func removingDuplicateQuantities() -> [HealthKitMeasurement] {
        var addedDict = [HealthKitMeasurement: Bool]()
        
        return filter {
            let rounded = $0.rounded(toPlaces: 2)
            return addedDict.updateValue(true, forKey: rounded) == nil
        }
    }
}

extension HealthKitMeasurement {
    func rounded(toPlaces places: Int) -> HealthKitMeasurement {
        HealthKitMeasurement(
            id: id,
            prepID: prepID,
            value: value.rounded(toPlaces: places),
            date: date,
            sourceName: sourceName,
            sourceBundleIdentifier: sourceBundleIdentifier
        )
    }
}
