import SwiftUI

struct DietaryEnergyPointSourceImage: View {
    
    let source: DietaryEnergyPointSource
    
    var body: some View {
        switch source {
        case .healthKit:
            Image("AppleHealthIcon")
                .resizable()
                .frame(width: 24, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(.systemGray3), lineWidth: 0.5)
                )
        case .fasted:
            Text("0")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(.label))
                .monospaced()
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(Color(.systemGray4))
                )
        default:
            Image(systemName: source.image)
                .scaleEffect(source.imageScale)
                .foregroundStyle(Color(.label))
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(Color(.systemGray4))
                )
        }
    }
}
