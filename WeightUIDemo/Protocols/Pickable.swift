//import Foundation
//
//public protocol Pickable: Hashable, CaseIterable {
//    var pickedTitle: String { get }
//    var pluralPickedTitle: String { get }
//
//    var menuTitle: String { get }
//    var pluralMenuTitle: String { get }
//    
//    var menuImage: String { get }
//    
//    var detail: String? { get }
//    
//    var description: String? { get }
//    static var `default`: Self { get }
//    
//    /// An optional option that is identified as "None", which would be placed in its own section
//    static var noneOption: Self? { get }
//}
//
//public extension Pickable {
//    var detail: String? { nil }
//    var description: String? { nil }
//    var menuImage: String { "" }
//    var pluralMenuTitle: String { menuTitle }
//    var pluralPickedTitle: String { pickedTitle }
//    static var noneOption: Self? { nil }
//}
