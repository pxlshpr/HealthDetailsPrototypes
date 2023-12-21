//import SwiftUI
//
//struct DailyValueTypePicker: View {
//    
//    @Binding var type: DailyValueType
//    @Binding var value: Double
//    var isDisabled: Binding<Bool>?
//    let header: String
//    
//    init(
//        type: Binding<DailyValueType>,
//        value: Binding<Double>,
//        header: String = "Daily Weight",
//        isDisabled: Binding<Bool>? = nil
//    ) {
//        _type = type
//        _value = value
//        self.header = header
//        self.isDisabled = isDisabled
//    }
//
//    var body: some View {
//        return Section(header: Text(header)) {
//            Picker("", selection: binding) {
//                Text("Average").tag(0)
//                Text("Last").tag(1)
//                Text("First").tag(2)
//            }
//            .pickerStyle(.segmented)
//            .disabled(isDisabled?.wrappedValue ?? false)
//        }
//    }
//    
//    var footer: some View {
//        var string: String {
//            switch type {
//            case 0: "Use the average of all weights entered for the day if there are multiple available."
//            case 1: "Use the last weight of the day if there are multiple available."
//            case 2: "Use the first weight of the day if there are multiple available."
//            default: ""
//            }
//        }
//        return Text(string)
//    }
//}
