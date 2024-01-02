import SwiftUI

public struct TopButtonLabel: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let fontSize: CGFloat
    let backgroundStyle: BackgroundStyle
    let systemImage: String
    
    public init(
        systemImage: String,
        forUseOutsideOfNavigationBar: Bool = false,
        backgroundStyle: BackgroundStyle = .standard
    ) {
        self.fontSize = forUseOutsideOfNavigationBar ? 30 : 24
        self.backgroundStyle = backgroundStyle
        self.systemImage = systemImage
    }
    
    public var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: fontSize))
            .symbolRenderingMode(.palette)
            .foregroundStyle(foregroundColor, backgroundColor)
    }
    
    var foregroundColor: Color {
        Color(hex: colorScheme == .light ? "838388" : "A0A0A8")
    }
    
    var backgroundColor: Color {
        switch backgroundStyle {
        case .standard:
#if os(iOS)
            return Color(.quaternaryLabel).opacity(0.5)
#else
            return Color(.quaternaryLabelColor).opacity(0.5)
#endif
//            return Color(hex: colorScheme == .light ? "EEEEEF" : "313135")
        case .forPlacingOverMaterials:
#if os(iOS)
            return colorScheme == .light
            ? Color(hex: "EEEEEF").opacity(0.5)
            : Color(.quaternaryLabel).opacity(0.5)
#else
            return colorScheme == .light
            ? Color(hex: "EEEEEF").opacity(0.5)
            : Color(.quaternaryLabelColor).opacity(0.5)
#endif
        }
    }
    
    public enum BackgroundStyle {
        case standard
        case forPlacingOverMaterials
    }
}
