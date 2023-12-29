import SwiftUI

struct FormTitle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textCase(.none)
            .font(.system(.title3, design: .rounded, weight: .semibold))
            .foregroundStyle(Color(.label))
    }
}

extension View {
    func formTitleStyle() -> some View {
        modifier(FormTitle())
    }
}

struct InfoEquation: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    func body(content: Content) -> some View {
        content
            .font(.footnote)
            .padding(5)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .foregroundStyle(Color(.secondarySystemFill))
            )
    }
}

extension View {
    func infoEquationStyle() -> some View {
        modifier(InfoEquation())
    }
}
