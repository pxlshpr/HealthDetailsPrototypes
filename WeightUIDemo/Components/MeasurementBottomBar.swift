import SwiftUI

struct MeasurementBottomBar: View {

    var int: Binding<Int?>?
    var intUnitString: String?

    @Binding var double: Double?
    @Binding var doubleString: String?
    var emptyValueString: Binding<String>?
    @Binding var isDisabled: Bool
    
    let doubleUnitString: String
    
    let isStyledAsBottomBar: Bool

    init(
        int: Binding<Int?>? = nil,
        intUnitString: String? = nil,

        double: Binding<Double?>,
        doubleString: Binding<String?>,
        doubleUnitString: String,

        emptyValueString: Binding<String>? = nil,
        
        isDisabled: Binding<Bool>,
        
        isStyledAsBottomBar: Bool = true
    ) {
        self.int = int
        self.intUnitString = intUnitString
        self.emptyValueString = emptyValueString
        _double = double
        _doubleString = doubleString
        _isDisabled = isDisabled
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
                isDisabled: $isDisabled
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
    @Binding var isDisabled: Bool

    var emptyValueString: Binding<String>?

    let doubleUnitString: String

    init(
        int: Binding<Int?>? = nil,
        intUnitString: String? = nil,

        double: Binding<Double?>,
        doubleString: Binding<String?>,
        doubleUnitString: String,

        emptyValueString: Binding<String>? = nil,

        isDisabled: Binding<Bool>
    ) {
        self.int = int
        self.intUnitString = intUnitString
        self.emptyValueString = emptyValueString
        _double = double
        _doubleString = doubleString
        _isDisabled = isDisabled
        self.doubleUnitString = doubleUnitString
    }
    
    @ViewBuilder
    var body: some View {
        if let double {
            if let int = int?.wrappedValue, let intUnitString {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(int)")
                        .contentTransition(.numericText(value: Double(int)))
                        .font(LargeNumberFont)
                        .foregroundStyle(isDisabled ? .secondary : .primary)
                    Text(intUnitString)
                        .font(LargeUnitFont)
                        .foregroundStyle(isDisabled ? .tertiary : .secondary)
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("\(doubleString ?? double.clean)")
                    .contentTransition(.numericText(value: double))
                    .font(LargeNumberFont)
                    .foregroundStyle(isDisabled ? .secondary : .primary)
                Text(doubleUnitString)
                    .font(LargeUnitFont)
                    .foregroundStyle(isDisabled ? .tertiary : .secondary)
            }
        } else {
            ZStack {
                
                /// dummy text placed to ensure height stays consistent
                Text("0")
                    .font(LargeNumberFont)
                    .opacity(0)

                Text(emptyValueString?.wrappedValue ?? "Not Set")
                    .font(LargeUnitFont)
                    .foregroundStyle(isDisabled ? .tertiary : .secondary)
            }
        }
    }
}
