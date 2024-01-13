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
    let date: Date?
    let imageName: String

    init(
        title: String,
        message: String,
        date: Date? = nil,
        imageName: String
    ) {
        self.title = title
        self.message = message
        self.date = date
        self.imageName = imageName
    }
    
    static func legacy(_ date: Date? = nil) -> Notice {
        .init(
//            title: "Legacy Data",
//            message: "You are viewing legacy data which has been preserved to ensure any dependent goals\(date != nil ? " on this date" : "") remain unchanged.",
            title: "Past Health Details",
            message: "You are viewing your Health Details for a past date. Changes will not affected your current health details but may affect the goals you had set on that day.",
            date: date,
            imageName: "calendar.badge.clock"
        )
    }
}

struct NoticeSection: View {
    
    let style: NoticeStyle
    let title: String?
    let message: String
    let date: Date?
    let primaryAction: NoticeAction?
    let secondaryAction: NoticeAction?
    let imageName: String?
    
    static func legacy(_ date: Date? = nil) -> Self {
        NoticeSection(notice: .legacy(date))
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
        self.date = notice.date
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
        self.date = nil
    }
    
    var body: some View {
        Section {
            noticeRow
            dateRow
        }
        .listRowBackground(background)
    }
    
    var noticeRow: some View {
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
    
    @ViewBuilder
    var dateRow: some View {
        if let date {
            HStack {
                Text("Date")
                Spacer()
                Text(date.shortDateString)
            }
        }
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
