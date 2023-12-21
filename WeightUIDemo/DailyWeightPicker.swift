import SwiftUI

struct DailyWeightPicker: View {
    
    @Binding var dailyWeightType: Int
    @Binding var value: Double
    var isDisabled: Binding<Bool>?
    
    init(
        dailyWeightType: Binding<Int>,
        value: Binding<Double>,
        isDisabled: Binding<Bool>? = nil
    ) {
        _dailyWeightType = dailyWeightType
        _value = value
        self.isDisabled = isDisabled
    }

    var body: some View {
        return Section(header: header, footer: footer) {
            Picker("", selection: binding) {
                Text("Average").tag(0)
                Text("Last").tag(1)
                Text("First").tag(2)
            }
            .pickerStyle(.segmented)
            .disabled(isDisabled?.wrappedValue ?? false)
        }
    }
    
    var footer: some View {
        var string: String {
            switch dailyWeightType {
            case 0: "Use the average of all weights entered for the day if there are multiple available."
            case 1: "Use the last weight of the day if there are multiple available."
            case 2: "Use the first weight of the day if there are multiple available."
            default: ""
            }
        }
        return Text(string)
    }
    
    var binding: Binding<Int> {
        Binding<Int>(
            get: { dailyWeightType },
            set: {
                dailyWeightType = $0
                withAnimation {
                    value = switch dailyWeightType {
                    case 0: 93.6
                    case 1: 92.5
                    default: 93.7
                    }
                }
            }
        )
    }
    
    var header: some View {
        Text("Daily Weight")
    }
}

struct DailyLeanBodyMassPicker: View {
    
    @Binding var dailyWeightType: Int
    @Binding var value: Double
    var isDisabled: Binding<Bool>?
    
    init(
        dailyWeightType: Binding<Int>,
        value: Binding<Double>,
        isDisabled: Binding<Bool>? = nil
    ) {
        _dailyWeightType = dailyWeightType
        _value = value
        self.isDisabled = isDisabled
    }

    var body: some View {
        return Section(header: header, footer: footer) {
            Picker("", selection: binding) {
                Text("Average").tag(0)
                Text("Last").tag(1)
                Text("First").tag(2)
            }
            .pickerStyle(.segmented)
            .disabled(isDisabled?.wrappedValue ?? false)
        }
    }
    
    var footer: some View {
        var string: String {
            switch dailyWeightType {
            case 0: "Use the average of all lean body mass data for the day if there are multiple available."
            case 1: "Use the last lean body mass data of the day if there are multiple available."
            case 2: "Use the first lean body mass data of the day if there are multiple available."
            default: ""
            }
        }
        return Text(string)
    }
    
    var binding: Binding<Int> {
        Binding<Int>(
            get: { dailyWeightType },
            set: {
                dailyWeightType = $0
                withAnimation {
                    value = switch dailyWeightType {
                    case 0: 93.6
                    case 1: 92.5
                    default: 93.7
                    }
                }
            }
        )
    }
    
    var header: some View {
        Text("Daily Lean Body Mass")
    }
}
