import Foundation
import PrepShared

enum PercentUnit: CaseIterable {
    case percent
}

extension PercentUnit: HealthUnit {
    var abbreviation: String { "%" }
    func intComponent(_ value: Double, in other: PercentUnit) -> Int? { nil }
    func doubleComponent(_ value: Double, in other: PercentUnit) -> Double { value }
    var intUnitString: String? { nil }
    var doubleUnitString: String { "%" }
    var pickedTitle: String { "" }
    var menuTitle: String  { "" }
    static var `default`: PercentUnit = .percent
}
