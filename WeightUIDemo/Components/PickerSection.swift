import SwiftUI
import PrepShared
import PrepShared

public struct PickerSection<T: Pickable>: View {
    
    let options: [T]
    let binding: Binding<T>
    let title: String?
    let disabledOptions: [T]
    let isDisabledBinding: Binding<Bool>
    
    public init(
        _ options: [T],
        _ binding: Binding<T>,
        _ title: String? = nil,
        disabledOptions: [T] = [],
        isDisabled: Binding<Bool> = .constant(false)
    ) {
        self.options = options
        self.binding = binding
        self.title = title
        self.disabledOptions = disabledOptions
        self.isDisabledBinding = isDisabled
    }

    public init(
        _ binding: Binding<T>,
        _ title: String? = nil,
        disabledOptions: [T] = [],
        isDisabled: Binding<Bool> = .constant(false)
    ) {
        self.options = T.allCases as! [T]
        self.binding = binding
        self.title = title
        self.disabledOptions = disabledOptions
        self.isDisabledBinding = isDisabled
    }

    public init(
        _ binding: Binding<T?>,
        _ title: String? = nil,
        disabledOptions: [T] = [],
        isDisabled: Binding<Bool> = .constant(false)
    ) {
        self.options = T.allCases as! [T]
        self.binding = Binding<T>(
            get: { binding.wrappedValue ?? T.noneOption ?? T.default },
            set: { binding.wrappedValue = $0 }
        )
        self.title = title
        self.disabledOptions = disabledOptions
        self.isDisabledBinding = isDisabled
    }

    public init(
        _ options: [T],
        _ binding: Binding<T?>,
        _ title: String?,
        disabledOptions: [T] = [],
        isDisabled: Binding<Bool> = .constant(false)
    ) {
        self.options = options
        self.binding = Binding<T>(
            get: { binding.wrappedValue ?? T.noneOption ?? T.default },
            set: { binding.wrappedValue = $0 }
        )
        self.title = title
        self.disabledOptions = disabledOptions
        self.isDisabledBinding = isDisabled
    }
    
    public var body: some View {
        Section(header: header) {
            ForEach(options, id: \.self) { option in
                button(for: option)
            }
        }
    }
    
    func button(for option: T) -> some View {
        Button {
            binding.wrappedValue = option
        } label: {
            label(for: option)
        }
        .disabled(optionIsDisabled(option))
    }
    
    func optionIsDisabled(_ option: T) -> Bool {
        disabledOptions.contains(option) || isDisabled
    }
    
    var isDisabled: Bool {
        isDisabledBinding.wrappedValue == true
    }
    
    func label(for option: T) -> some View {
        var checkmark: some View {
            Image(systemName: "checkmark")
                .opacity(binding.wrappedValue == option ? 1 : 0)
        }
        
        var disabled: Bool {
            optionIsDisabled(option)
        }
        
        var primaryColor: Color {
            disabled ? Color(.tertiaryLabel) : Color(.label)
        }

        var secondaryColor: Color {
            disabled ? Color(.quaternaryLabel) : Color(.secondaryLabel)
        }

        var content: some View {
            func withDescription(_ description: String) -> some View {
                VStack(alignment: .leading) {
                    Text(option.menuTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(primaryColor)
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(secondaryColor)
                }
            }
            
            var standard: some View {
                Text(option.menuTitle)
                    .foregroundStyle(primaryColor)
            }
            
            return Group {
                if let description = option.description {
                    withDescription(description)
                } else {
                    standard
                }
            }
        }
        
        @ViewBuilder
        var detail: some View {
            if let detail = option.detail {
                Text(detail)
                    .foregroundStyle(secondaryColor)
            }
        }
        
        return HStack {
            checkmark
            content
            Spacer()
            detail
        }
    }
    
    @ViewBuilder
    var header: some View {
        if let title {
            Text(title)
        }
    }
}
