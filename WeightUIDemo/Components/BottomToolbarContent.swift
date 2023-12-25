import SwiftUI

func bottomToolbarContent(
    value: Double,
    valueString: String? = nil,
    isDisabled: Bool,
    unitString: String
) -> some ToolbarContent {
    ToolbarItem(placement: .bottomBar) {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Spacer()
            Text("\(valueString ?? value.clean)")
                .contentTransition(.numericText(value: value))
                .font(LargeNumberFont)
                .foregroundStyle(isDisabled ? .secondary : .primary)
            Text(unitString)
                .font(LargeUnitFont)
                .foregroundStyle(isDisabled ? .tertiary : .secondary)
        }
    }
}
