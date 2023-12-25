import SwiftUI

struct IntervalPicker: View {
    
    @Binding var interval: HealthInterval
    let periods: [HealthPeriod]?
    let ranges: [HealthPeriod: ClosedRange<Int>]?
    let title: String?
    @Binding var isDisabled: Bool
    
    init(
        interval: Binding<HealthInterval>,
        periods: [HealthPeriod]? = nil,
        ranges: [HealthPeriod: ClosedRange<Int>]? = nil,
        title: String? = nil,
        isDisabled: Binding<Bool> = .constant(false)
    ) {
        _interval = interval
        self.periods = periods
        self.ranges = ranges
        self.title = title
        _isDisabled = isDisabled
    }
    
    var body: some View {
        Section(header: header) {
            HStack(spacing: 3) {
                stepper
                Spacer()
                value
                periodPicker
            }
        }
    }
    
    var value: some View {
        Text("\(interval.value)")
//            .font(NumberFont)
            .contentTransition(.numericText(value: Double(interval.value)))
            .foregroundStyle(isDisabled ? .secondary : .primary)
    }
    
    func range(for period: HealthPeriod) -> ClosedRange<Int> {
        ranges?[period] ?? 1...period.maxValue
    }
    
    var stepper: some View {
        
//        let binding = Binding<Int>(
//            get: { interval.value },
//            set: { newValue in
//
//            }
//        )
        return Stepper(
            "",
            value: $interval.value,
            in: range(for: interval.period)
        )
        .fixedSize()
        .disabled(isDisabled)
    }
    
    var periodBinding: Binding<HealthPeriod> {
        Binding<HealthPeriod>(
            get: {
                interval.period
            },
            set: { newValue in
                interval.period = newValue

                /// If  a range for this period was provided
                let range = range(for: newValue)

                /// Ensure the value is within the range
                if interval.value < range.lowerBound {
                    interval.value = range.lowerBound
                }
                if interval.value > range.upperBound {
                    interval.value = range.upperBound
                }
            }
        )
    }
    
    var periodPicker: some View {
        Group {
            if let periods {
                MenuPicker(
                    periods,
                    periodBinding,
                    isPlural: interval.value != 1,
                    isDisabled: $isDisabled
                )
            } else {
                MenuPicker(
                    $interval.period,
                    isPlural: interval.value != 1,
                    isDisabled: $isDisabled
                )
            }
        }
        .fixedSize()
    }
    
    @ViewBuilder
    var header: some View {
        if let title {
            Text(title)
        }
    }
}

import Foundation

public struct HealthInterval: Hashable, Codable, Equatable {
    public var value: Int
    public var period: HealthPeriod
    public var date: Date?
    
    public init(_ value: Int, _ period: HealthPeriod, date: Date? = nil) {
        self.value = value
        self.period = period
        self.date = date
    }
    
    public static var `default`: HealthInterval {
        .init(1, .week)
    }
}

public extension HealthInterval {
    var numberOfDays: Int {
        switch period {
        case .day:      value
        case .week:     value * 7
            
        /// [ ]  Use the date to precisely find out how many days ago was `value` months (get the current day `value` months back, and calculate the number of days)
        case .month:    value * 30
        }
    }
}

public extension HealthInterval {
    
    func equalsWithoutTimestamp(_ other: HealthInterval) -> Bool {
        value == other.value && period == other.period
    }
    
    var greaterIntervals: [HealthInterval] {
        let all = Self.allIntervals
        guard let index = all.firstIndex(where: { $0.value == self.value && $0.period == self.period }),
              index + 1 < all.count
        else { return [] }
        return Array(all[index+1..<all.count])
    }
    
    static var allIntervals: [HealthInterval] {
        /// Prefill `(1, .day)` because 1 isn't included in the possible values for `.day`
        var intervals: [HealthInterval] = [.init(1, .day)]
        for period in HealthPeriod.allCases {
            for value in period.minValue...period.maxValue {
                intervals.append(.init(value, period))
            }
        }
        return intervals
    }
    
    var intervalType: HealthIntervalType {
        get {
            switch period {
            case .day:
                switch value {
                case 0:     .sameDay
                case 1:     .previousDay
                default:    .average
                }
            default:    .average
            }
        }
        set {
            switch newValue {
            case .average:
                value = 2
                period = .week
            case .sameDay:
                value = 0
                period = .day
            case .previousDay:
                value = 1
                period = .day
            }
        }
    }
    
    mutating func correctIfNeeded() {
        if value < period.minValue {
            value = period.minValue
        }
        if value > period.maxValue {
            value = period.maxValue
        }
    }

    func startDate(with date: Date) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let endDate = calendar.startOfDay(for: date)
        return calendar.date(
            byAdding: period.calendarComponent,
            value: -value,
            to: endDate
        )!
    }
    
    func dateRange(with date: Date) -> ClosedRange<Date> {
        let calendar = Calendar(identifier: .gregorian)
        let startDate = startDate(with: date)
        let endDate = calendar.startOfDay(for: date)
        switch (value, period) {
        case (0, .day):
            return startDate.moveDayBy(-1)...endDate
        default:
            return startDate.moveDayBy(-1)...endDate.moveDayBy(-1)
        }
    }
    
    var dateRange: ClosedRange<Date>? {
        period.dateRangeOfPast(value)
    }
    
    var isLatest: Bool {
        value == 1 && period == .day
    }
    
    var isToday: Bool {
        value == 0 && period == .day
    }
}

extension HealthInterval: CustomStringConvertible {
    public var description: String {
        "\(value) \(period.name)"
    }
}

import Foundation

public enum HealthPeriod: Int16, Codable, CaseIterable {
    case day = 1
    case week
    case month
}

public extension HealthPeriod {
    var range: ClosedRange<Int> {
        minValue...maxValue
    }
}

public extension HealthPeriod {
    
    var name: String {
        switch self {
        case .day:      "day"
        case .week:     "week"
        case .month:    "month"
        }
    }
    
    var plural: String {
        switch self {
        case .day:      "days"
        case .week:     "weeks"
        case .month:    "months"
        }
    }
}

public extension HealthPeriod {
    
    var minValue: Int {
        switch self {
        case .day:  2
        default:    1
        }
    }
    
    var maxValue: Int {
        switch self {
        case .day:      6
        case .week:     3
        case .month:    12
        }
    }
    
    var calendarComponent: Calendar.Component {
        switch self {
        case .day:      .day
        case .month:    .month
        case .week:     .weekOfMonth
        }
    }

    func dateRangeOfPast(_ value: Int, to date: Date = Date()) -> ClosedRange<Date>? {
        
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: date)
        let endDate = startOfDay

        guard let startDate = calendar.date(
            byAdding: calendarComponent,
            value: -value,
            to: endDate
        ) else {
            return nil
        }

        return startDate.moveDayBy(-1)...endDate.moveDayBy(-1)
    }
}

extension HealthPeriod: Pickable {
    public var pickedTitle: String { name }
    public var menuTitle: String { name }
    public var pluralPickedTitle: String { plural }
    public var pluralMenuTitle: String { plural }
    public static var `default`: HealthPeriod { .week }
}

import SwiftUI

public struct MenuPicker<T: Pickable>: View {

    @Binding var isDisabled: Bool
    let options: [T]
    let binding: Binding<T>
    let isPlural: Bool

    //MARK: - Initializers
    
    public init(
        _ options: [T],
        _ binding: Binding<T>,
        isPlural: Bool = false,
        isDisabled: Binding<Bool> = .constant(false)
    ) {
        self.options = options
        self.binding = binding
        self.isPlural = isPlural
        _isDisabled = isDisabled
    }

    public init(
        _ binding: Binding<T>,
        isPlural: Bool = false,
        isDisabled: Binding<Bool> = .constant(false)
    ) {
        self.options = T.allCases as! [T]
        self.binding = binding
        self.isPlural = isPlural
        _isDisabled = isDisabled
    }

    public init(
        _ binding: Binding<T?>,
        isPlural: Bool = false,
        isDisabled: Binding<Bool> = .constant(false)
    ) {
        self.options = T.allCases as! [T]
        self.binding = Binding<T>(
            get: { binding.wrappedValue ?? T.noneOption ?? T.default },
            set: { binding.wrappedValue = $0 }
        )
        self.isPlural = isPlural
        _isDisabled = isDisabled
    }

    public init(
        _ options: [T],
        _ binding: Binding<T?>,
        isPlural: Bool = false,
        isDisabled: Binding<Bool> = .constant(false)
    ) {
        self.options = options
        self.binding = Binding<T>(
            get: { binding.wrappedValue ?? T.noneOption ?? T.default },
            set: { binding.wrappedValue = $0 }
        )
        self.isPlural = isPlural
        _isDisabled = isDisabled
    }

    //MARK: - Body
    
    public var body: some View {
        Menu {
            Picker(selection: binding, label: EmptyView()) {
                noneContent
                optionsContent
            }
        } label: {
            label
        }
        .padding(.leading, 5)
        .padding(.vertical, 3)
        .contentShape(Rectangle())
        .hoverEffect(.highlight)
        .animation(.none, value: binding.wrappedValue)
    }
    
    var optionsWithoutNone: [T] {
        if let none = T.noneOption {
            options.filter { $0 != none }
        } else {
            options
        }
    }
    
    @ViewBuilder
    var noneContent: some View {
        if let none = T.noneOption, options.contains(none) {
            Text(isPlural ? none.pluralMenuTitle : none.menuTitle)
                .font(.body)
                .textCase(.none)
                .tag(none)
            Divider()
        }
    }
    
    var optionsContent: some View {
        ForEach(optionsWithoutNone, id: \.self) { option in
            Group {
                if option.menuImage.isEmpty {
                    Text(isPlural ? option.pluralMenuTitle : option.menuTitle)
                } else {
                    Label(option.menuTitle, systemImage: option.menuImage)
                }
            }
            .font(.body)
            .textCase(.none)
            .tag(option)
        }
    }
    
    var label: some View {
        HStack(spacing: 4) {
            Text(isPlural ? binding.wrappedValue.pluralPickedTitle : binding.wrappedValue.pickedTitle)
                .textCase(.none)
            Image(systemName: "chevron.up.chevron.down")
                .imageScale(.small)
        }
        .font(.body)
//        .foregroundStyle(foregroundColor)
        .foregroundStyle(isDisabled ? Color(.secondaryLabel) : Color.accentColor)
    }
    
    var foregroundColor: Color {
        if let none = T.noneOption, binding.wrappedValue == none {
            Color(.tertiaryLabel)
        } else {
            Color(.secondaryLabel)
        }
    }
}
