import Foundation

struct LeanBodyMassData: Hashable, Identifiable {
    let id: Int
    let source: LeanBodyMassSource
    let date: Date
    let value: Double
    
    init(
        _ id: Int,
        _ source: LeanBodyMassSource,
        _ date: Date,
        _ value: Double
    ) {
        self.id = id
        self.source = source
        self.date = date
        self.value = value
    }
    
    var valueString: String {
        "\(value.clean) kg"
    }
    
    var dateString: String {
        date.shortTime
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