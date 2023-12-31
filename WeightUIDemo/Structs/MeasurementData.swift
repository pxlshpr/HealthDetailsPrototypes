import Foundation

struct MeasurementData: Hashable, Identifiable {
    let id: Int
    let healthKitUUID: UUID?
    let date: Date
    let value: Double
    
    init(
        _ id: Int,
        _ date: Date,
        _ value: Double,
        _ healthKitUUID: UUID? = nil
    ) {
        self.id = id
        self.healthKitUUID = healthKitUUID
        self.date = date
        self.value = value
    }
    
    func valueString(unit: String) -> String {
        "\(value.clean) \(unit)"
    }
    
    var dateString: String {
        date.shortTime
    }
    
    var isFromHealthKit: Bool {
        healthKitUUID != nil
    }
}

extension MeasurementData: Comparable {
    static func < (lhs: MeasurementData, rhs: MeasurementData) -> Bool {
        lhs.date < rhs.date
    }
}
