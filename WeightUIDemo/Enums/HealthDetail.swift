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
        case .sex: "Biological Sex"
        case .height: "Height"
        case .weight: "Weight"
        case .leanBodyMass: "Lean Body Mass"
        case .preganancyStatus: "Pregnancy Status"
        case .smokingStatus: "Smoking Status"
        }
    }
    
    var syncName: String {
        switch self {
        case .leanBodyMass: "Lean Body Mass and Fat Percentage"
        default: name
        }
    }
    
    /// Not related to time—once set, the value is brought forward to every future HealthDetail until changed
    var isNonTemporal: Bool {
        switch self {
        case .age, .sex, .smokingStatus:
            true
        default: 
            false
        }
    }
    
    /// Directly related to the date it's set on. When referenced, the date is displayed for these as they can potentially change on any future date.
    var isTemporal: Bool {
        switch self {
        case .height, .weight, .leanBodyMass, .preganancyStatus, .maintenance:
            true
        default: 
            false
        }
    }
    
    static var allNonTemporalHealthDetails: [HealthDetail] {
        allCases.filter{ $0.isNonTemporal }.sorted()
    }
    
    static var allTemporalHealthDetails: [HealthDetail] {
        allCases.filter{ $0.isTemporal }.sorted()
    }
}

extension HealthDetail: Comparable {
    static func < (lhs: HealthDetail, rhs: HealthDetail) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension Array where Element == HealthDetail {
    var nonTemporalHealthDetails: [HealthDetail] {
        filter{ $0.isNonTemporal }.sorted()
    }
    
    var temporalHealthDetails: [HealthDetail] {
        filter{ $0.isTemporal }.sorted()
    }
    
    var containsAllCases: Bool {
        HealthDetail.allCases.allSatisfy { contains($0) }
    }
}

