import SwiftUI

struct InfoSection: View {
    
    enum Style {
        case largeTitle
        case standardTitle
    }
    
    let title: String
    let description: String
    let style: Style
    
    init(_ title: String, _ description: String, style: Style = .largeTitle) {
        self.title = title
        self.description = description
        self.style = style
    }
    
    var body: some View {
        Section(header: header) {
            Text(description)
        }
    }
    
    var header: some View {
        HStack(alignment: .bottom) {
            switch style {
            case .largeTitle:
                Text(title)
                    .textCase(.none)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color(.label))
            case .standardTitle:
                Text(title)
            }
             Spacer()
        }
    }
}
