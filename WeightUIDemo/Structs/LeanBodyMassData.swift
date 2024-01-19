import Foundation

struct LeanBodyMassData: Codable, Hashable, Identifiable {
    let id: Int
    let source: MeasurementSource
    let date: Date
    let value: Double
    let fatPercentage: Double?
    
    init(
        _ id: Int,
        _ source: MeasurementSource,
        _ date: Date,
        _ value: Double,
        _ fatPercentage: Double? = nil
    ) {
        self.id = id
        self.source = source
        self.date = date
        self.value = value
        self.fatPercentage = fatPercentage
    }
    
    var valueString: String {
        "\(value.clean) kg"
    }
    
    var dateString: String {
        date.healthTimeString
    }
    
    func fatPercentage(forWeight weight: Double) -> Double {
        (((weight - value) / weight) * 100.0).rounded(toPlaces: 1)
    }
}

extension LeanBodyMassData: Comparable {
    static func < (lhs: LeanBodyMassData, rhs: LeanBodyMassData) -> Bool {
        lhs.date < rhs.date
    }
}
