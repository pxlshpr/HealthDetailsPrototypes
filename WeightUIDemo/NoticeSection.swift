import SwiftUI

//MARK: - Notice

struct NoticeAction {
    let title: String
    let onTrigger: () -> ()
}

enum NoticeStyle {
    case accentColor
    case plain
}

struct NoticeSection<Content>: View where Content: View {
    
    let style: NoticeStyle
    let title: String?
    let message: String
    let primaryAction: NoticeAction?
    let secondaryAction: NoticeAction?
    let image: () -> Content?
    
    init(
        style: NoticeStyle = .accentColor,
        title: String? = nil,
        message: String,
        primaryAction: NoticeAction? = nil,
        secondaryAction: NoticeAction? = nil,
        @ViewBuilder image: @escaping () -> Content? = { nil }
    ) {
        self.style = style
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.image = image
    }
    
    var body: some View {
        Section {
            HStack(alignment: .top) {
                if image() != nil {
                    VStack {
                        image()
                        Spacer()
                    }
                }
                VStack(alignment: .leading) {
                    titleView
                    messageView
                    divider
                    primaryButton
                    secondaryButton
                }
            }
            .padding(.top)
        }
        .listRowBackground(background)
    }
    
    var buttonColor: Color {
        style == .plain ? Color.accentColor : Color(.label)
    }
    
    @ViewBuilder
    var primaryButton: some View {
        if let primaryAction {
            Button(primaryAction.title) {
                primaryAction.onTrigger()
            }
            .foregroundStyle(buttonColor)
            .fontWeight(.bold)
            .padding(.top, 5)
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    var secondaryButton: some View {
        if let secondaryAction {
            Button(secondaryAction.title) {
                secondaryAction.onTrigger()
            }
            .foregroundStyle(buttonColor)
            .padding(.top, 5)
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    var titleView: some View {
        if let title {
            Text(title)
                .font(.headline)
//                .padding(.bottom, 2)
//                .fontWeight(.semibold)
        }
    }
    var messageView: some View {
        Text(message)
            .font(.system(.callout))
            .foregroundStyle(Color(.label))
            .opacity(0.8)
    }
    
    @ViewBuilder
    var divider: some View {
        if primaryAction != nil || secondaryAction != nil {
            Divider()
                .overlay(Color(.label))
                .opacity(0.6)
        }
    }
    
    @ViewBuilder
    var background: some View {
//        if style == .accentColor {
//            Rectangle().fill(Color.accentColor)
            Rectangle().fill(Color(.secondarySystemGroupedBackground))
//            Rectangle().fill(Color.accentColor.gradient)
//        }
    }
    
}
