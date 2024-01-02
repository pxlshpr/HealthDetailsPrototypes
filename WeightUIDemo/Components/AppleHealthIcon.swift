import SwiftUI

struct AppleHealthIcon: View {
    
    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24
    let cornerRadius: CGFloat = 5
    let lineWidth: CGFloat = 0.5

    var body: some View {
        Image("AppleHealthIcon")
            .resizable()
            .frame(width: imageScale * scale, height: imageScale * scale)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius * scale)
                    .stroke(Color(.systemGray3), lineWidth: lineWidth * scale)
            )
    }
}

struct ScalableIcon: View {
    
    let systemName: String
    
    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24

    var body: some View {
        Image(systemName: systemName)
            .frame(width: imageScale * scale, height: imageScale * scale)
    }
}
