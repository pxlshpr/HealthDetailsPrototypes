import SwiftUI

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
                ZStack {
                    
                    /// dummy text placed to ensure height stays consistent
                    Text("0")
                        .font(LargeNumberFont)
                        .opacity(0)

                    Text("Not Set")
                        .font(LargeUnitFont)
                        .foregroundStyle(isDisabled ? .tertiary : .secondary)
                }
            }
        }
        .padding(.horizontal, BottomValueHorizontalPadding)
        .padding(.vertical, BottomValueVerticalPadding)
        .background(.bar)
    }
}
