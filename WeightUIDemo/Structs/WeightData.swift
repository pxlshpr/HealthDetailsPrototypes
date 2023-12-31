import Foundation

struct WeightData: Hashable, Identifiable {
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
    
    var valueString: String {
        "\(value.clean) kg"
    }
    
    var dateString: String {
        date.shortTime
    }
    
    var isFromHealthKit: Bool {
        healthKitUUID != nil
    }
}

extension WeightData: Comparable {
    static func < (lhs: WeightData, rhs: WeightData) -> Bool {
        lhs.date < rhs.date
    }
}
