import SwiftUI

struct MeasurementBottomBar: View {

    var int: Binding<Int?>?
    var intUnitString: String?

    @Binding var double: Double?
    @Binding var doubleString: String?
    var prefix: Binding<String?>?
    var emptyValueString: Binding<String>?
    
    let doubleUnitString: String
    
    let isStyledAsBottomBar: Bool

    init(
        int: Binding<Int?>? = nil,
        intUnitString: String? = nil,

        double: Binding<Double?>,
        doubleString: Binding<String?>,
        doubleUnitString: String,
        prefix: Binding<String?>? = nil,

        emptyValueString: Binding<String>? = nil,
        
        isStyledAsBottomBar: Bool = true
    ) {
        self.int = int
        self.intUnitString = intUnitString
        self.emptyValueString = emptyValueString
        self.prefix = prefix
        _double = double
        _doubleString = doubleString
        self.doubleUnitString = doubleUnitString
        self.isStyledAsBottomBar = isStyledAsBottomBar
    }
    
    @ViewBuilder
    var body: some View {
        if isStyledAsBottomBar {
            content
                .padding(.horizontal, BottomValueHorizontalPadding)
                .padding(.vertical, BottomValueVerticalPadding)
                .background(.bar)
        } else {
            content
        }
    }
    
    var content: some View {
        HStack {
            Spacer()
            MeasurementBottomText(
                int: int,
                intUnitString: intUnitString,
                double: $double,
                doubleString: $doubleString,
                doubleUnitString: doubleUnitString,
                emptyValueString: emptyValueString,
                prefix: prefix
            )
        }
    }
}

import SwiftUI

struct MeasurementBottomText: View {

    var int: Binding<Int?>?
    var intUnitString: String?

    @Binding var double: Double?
    @Binding var doubleString: String?

    var emptyValueString: Binding<String>?
    var prefix: Binding<String?>?

    let doubleUnitString: String

    init(
        int: Binding<Int?>? = nil,
        intUnitString: String? = nil,

        double: Binding<Double?>,
        doubleString: Binding<String?>,
        doubleUnitString: String,

        emptyValueString: Binding<String>? = nil,
        prefix: Binding<String?>? = nil
    ) {
        self.int = int
        self.intUnitString = intUnitString
        self.emptyValueString = emptyValueString
        self.prefix = prefix
        _double = double
        _doubleString = doubleString
        self.doubleUnitString = doubleUnitString
    }
    
    @ViewBuilder
    var body: some View {
        if let double {
            HStack {
                if let prefix = prefix?.wrappedValue {
                    Text(prefix)
                        .font(LargeNumberFont)
                        .foregroundStyle(.primary)
                }
                if let int = int?.wrappedValue, let intUnitString {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("\(int)")
                            .contentTransition(.numericText(value: Double(int)))
                            .font(LargeNumberFont)
                            .foregroundStyle(.primary)
                        Text(intUnitString)
                            .font(LargeUnitFont)
                            .foregroundStyle(.secondary)
                    }
                }
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(doubleString ?? double.clean)")
                        .contentTransition(.numericText(value: double))
                        .font(LargeNumberFont)
                        .foregroundStyle(.primary)
                    Text(doubleUnitString)
                        .font(LargeUnitFont)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            ZStack {
                
                /// dummy text placed to ensure height stays consistent
                Text("0")
                    .font(LargeNumberFont)
                    .opacity(0)

                Text(emptyValueString?.wrappedValue ?? NotSetString)
                    .font(LargeUnitFont)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
