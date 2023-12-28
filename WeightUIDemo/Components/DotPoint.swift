import SwiftUI

func dotPoint(_ string: String) -> some View {
    Label {
        Text(string)
    } icon: {
        Circle()
            .foregroundStyle(Color(.label))
            .frame(width: 5, height: 5)
    }
}
