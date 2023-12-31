import Foundation

enum HealthDetail: Int, Identifiable, CaseIterable {
    case maintenance = 1
    
    case age
    case sex
    case weight
    case leanBodyMass
    case height
    case preganancyStatus
    case smokingStatus
    
    var id: Int { rawValue }
    var name: String {
        switch self {
        case .maintenance:  "Maintenance Energy"
        case .age: "Age"
        case .sex: "Sex"
        case .height: "Height"
        case .weight: "Weight"
        case .leanBodyMass: "Lean Body Mass"
        case .preganancyStatus: "Pregnancy Status"
        case .smokingStatus: "Smoking Status"
        }
    }
    
    var isCharacteristic: Bool {
        switch self {
        case .age, .sex: true
        default: false
        }
    }
    
    var isMeasurement: Bool {
        switch self {
        case .height, .weight, .leanBodyMass: true
        default: false
        }
    }
}

extension HealthDetail: Comparable {
    static func < (lhs: HealthDetail, rhs: HealthDetail) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension Array where Element == HealthDetail {
    var characteristics: [HealthDetail] {
        filter{ $0.isCharacteristic }.sorted()
    }
    
    var measurements: [HealthDetail] {
        filter{ $0.isMeasurement }.sorted()
    }
}
