import SwiftUI

public struct CloseButtonLabel: View {
    
    let backgroundStyle: TopButtonLabel.BackgroundStyle
    let forUseOutsideOfNavigationBar: Bool
    
    public init(
        forUseOutsideOfNavigationBar: Bool = false,
        backgroundStyle: TopButtonLabel.BackgroundStyle = .standard
    ) {
        self.forUseOutsideOfNavigationBar = forUseOutsideOfNavigationBar
        self.backgroundStyle = backgroundStyle
    }
    
    public var body: some View {
        TopButtonLabel(
            systemImage: "xmark.circle.fill",
            forUseOutsideOfNavigationBar: forUseOutsideOfNavigationBar,
            backgroundStyle: backgroundStyle
        )
    }
}
