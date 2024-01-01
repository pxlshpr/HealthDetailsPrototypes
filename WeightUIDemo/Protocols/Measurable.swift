import Foundation

protocol Measurable: Identifiable {
    var id: UUID { get }
    var healthKitUUID: UUID? { get }
    var date: Date { get }
    var value: Double { get }
}

extension Measurable {
    var timeString: String {
        date.shortTime
    }
    
    var isFromHealthKit: Bool {
        healthKitUUID != nil
    }
    
    var imageType: MeasurementCell.ImageType {
        if isFromHealthKit {
            .healthKit
        } else {
            .systemImage("pencil")
        }
    }
}

extension Array where Element: Measurable {
    mutating func sort() {
        sort(by: { $0.date < $1.date })
    }
    
    func sorted() -> [Element] {
        return sorted(by: { $0.date < $1.date })
    }
}

//struct AnyMeasurable: Measurable {
//    private var _measurable: any Measurable
//    
//    init(_ measurable: some Measurable) {
//        _measurable = measurable /// Automatically casts to "any" type
//    }
//    
//    var id: UUID {
//        _measurable.id
//    }
//    
//    var healthKitUUID: UUID? {
//        _measurable.healthKitUUID
//    }
//    
//    var date: Date {
//        _measurable.date
//    }
//    
//    var value: Double {
//        _measurable.value
//    }
//}
