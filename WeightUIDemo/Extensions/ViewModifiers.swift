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
