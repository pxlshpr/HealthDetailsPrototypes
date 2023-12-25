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

struct Notice {
    let title: String
    let message: String
    let imageName: String
    
    static var legacy: Notice {
        .init(
            title: "Legacy Data",
//            message: "This data has been preserved to ensure any goals set on this day remain unchanged.",
            message: "This data has been preserved to ensure that any goals dependent on it remain unchanged.",
            imageName: "calendar.badge.clock"
        )
    }
}

struct NoticeSection: View {
    
    let style: NoticeStyle
    let title: String?
    let message: String
    let primaryAction: NoticeAction?
    let secondaryAction: NoticeAction?
    let imageName: String?
    
    static var legacy: Self {
        NoticeSection(notice: .legacy)
    }
    
    init(
        style: NoticeStyle = .accentColor,
        notice: Notice,
        primaryAction: NoticeAction? = nil,
        secondaryAction: NoticeAction? = nil
    ) {
        self.style = style
        self.title = notice.title
        self.message = notice.message
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.imageName = notice.imageName
    }
    
    init(
        style: NoticeStyle = .accentColor,
        title: String? = nil,
        message: String,
        primaryAction: NoticeAction? = nil,
        secondaryAction: NoticeAction? = nil
    ) {
        self.style = style
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.imageName = nil
    }
    
    var body: some View {
        Section {
            HStack(alignment: .top) {
                if let imageName {
                    VStack {
                        Image(systemName: imageName)
                            .frame(width: 30)
                            .imageScale(.large)
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
