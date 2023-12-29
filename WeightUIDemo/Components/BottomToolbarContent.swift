import SwiftUI

func bottomToolbarContent(
    value: Double?,
    valueString: String? = nil,
    isDisabled: Bool,
    unitString: String
) -> some ToolbarContent {
    ToolbarItem(placement: .bottomBar) {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Spacer()
            if let value {
                Text("\(valueString ?? value.clean)")
                    .contentTransition(.numericText(value: value))
                    .font(LargeNumberFont)
                    .foregroundStyle(isDisabled ? .secondary : .primary)
                Text(unitString)
                    .font(LargeUnitFont)
                    .foregroundStyle(isDisabled ? .tertiary : .secondary)
            } else {
                Text("Not Set")
                    .font(LargeUnitFont)
                    .foregroundStyle(isDisabled ? .tertiary : .secondary)
            }
        }
    }
}

struct BottomValue: View {

    @Binding var value: Double?
    @Binding var valueString: String?
    @Binding var isDisabled: Bool
    let unitString: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Spacer()
            if let value {
                Text("\(valueString ?? value.clean)")
                    .contentTransition(.numericText(value: value))
                    .font(LargeNumberFont)
                    .foregroundStyle(isDisabled ? .secondary : .primary)
                Text(unitString)
                    .font(LargeUnitFont)
                    .foregroundStyle(isDisabled ? .tertiary : .secondary)
            } else {
                Text("Not Set")
                    .font(LargeUnitFont)
                    .foregroundStyle(isDisabled ? .tertiary : .secondary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}
