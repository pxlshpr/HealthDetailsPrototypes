import SwiftUI
import SwiftSugar

enum DailyValueType: CaseIterable, Hashable {
    case average
    case last
    case first
    
    var name: String {
        switch self {
        case .average:
            "Average"
        case .last:
            "Last"
        case .first:
            "First"
        }
    }
    
    var description: String {
        switch self {
        case .average:
            "The average is being used."
        case .last:
            "The last entry is being used."
        case .first:
            "The first entry is being used."
        }
    }
}

struct WeightForm_Past: View {
    
    @Environment(\.dismiss) var dismiss

    @State var hasAppeared = false
    @State var dailyValueType: DailyValueType = .average
    @State var value: Double = 93.6
    @State var isEditing = false

    var body: some View {
        NavigationStack {
            Group {
                if hasAppeared {
                    Form {
                        explanation
                        if !isEditing {
                            notice
                        }
                        if isEditing {
                            dailyValuePicker
                        }
                        list
                    }
                } else {
                    Color.clear
                }
            }
            .navigationTitle("Weight")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                hasAppeared = true
            }
        }
    }
    
    var controlColor: Color {
        isEditing ? Color(.label) : Color(.secondaryLabel)
    }
    
    var isDisabled: Bool {
        !isEditing
    }
    
    var dailyValuePicker: some View {
        Section("Use") {
            Picker("", selection: $dailyValueType) {
                ForEach(DailyValueType.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .disabled(isDisabled)
        }
    }

    var notice: some View {
        var primaryAction: NoticeAction {
            .init(title: isEditing ? "View Preserved Data" : "Edit to View Actual Data") {
                withAnimation {
                    isEditing.toggle()
                }
            }
        }
        
        return NoticeSection(
            style: .plain,
            title: "Previous Data",
            message: "This data has been preserved to ensure any goals set on this day remain unchanged.",
//                primaryAction: primaryAction,
            image: {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 30))
                    .padding(5)
            }
        )
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        withAnimation {
                            isEditing = false
                        }
                    } else {
                        withAnimation {
                            isEditing = true
                        }
                    }
                }
                .fontWeight(.semibold)
            }
            ToolbarItem(placement: .topBarLeading) {
                if isEditing {
                    Button("Cancel") {
                        withAnimation {
                            isEditing = false
                        }
                    }
                }
            }
            ToolbarItem(placement: .bottomBar) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Spacer()
                    Text("\(value.clean)")
                        .contentTransition(.numericText(value: value))
                        .font(LargeNumberFont)
                        .foregroundStyle(isDisabled ? .secondary : .primary)
                    Text("kg")
                        .font(LargeUnitFont)
//                        .foregroundStyle(.secondary)
                        .foregroundStyle(isDisabled ? .tertiary : .secondary)
                }
            }
        }
    }

    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Your weight may be used when:")
                Label {
                    Text("Creating goals. For example, you could create a protein goal relative to your weight.")
                } icon: {
                    Circle()
                        .foregroundStyle(Color(.label))
                        .frame(width: 5, height: 5)
                }
                Label {
                    Text("Calculating your adaptive maintenance energy, estimated resting energy, or lean body mass.")
                } icon: {
                    Circle()
                        .foregroundStyle(Color(.label))
                        .frame(width: 5, height: 5)
                }
            }
        }
    }
    
    struct ListData: Hashable {
        let isHealth: Bool
        let dateString: String
        let valueString: String
        
        init(_ isHealth: Bool, _ dateString: String, _ valueString: String) {
            self.isHealth = isHealth
            self.dateString = dateString
            self.valueString = valueString
        }
    }
    
    let listData: [ListData] = [
        .init(false, "9:42 am", "93.7 kg"),
        .init(true, "12:07 pm", "94.6 kg"),
        .init(false, "5:35 pm", "92.5 kg"),
    ]
    
    func cell(for listData: ListData) -> some View {
        @ViewBuilder
        var image: some View {
            if listData.isHealth {
                Image("AppleHealthIcon")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(.systemGray3), lineWidth: 0.5)
                    )
            } else {
                Image(systemName: "pencil")
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundStyle(Color(.systemGray4))
                    )
            }
        }
        
        return HStack {
            image
                .opacity(isEditing ? 1 : 0.6)
            Text(listData.dateString)
            Spacer()
            Text(listData.valueString)
        }
        .foregroundStyle(controlColor)
    }
    
    var list: some View {
        var bottomContent: some View {
            
            var isEmpty: Bool {
                listData.isEmpty
            }
            
            var label: String {
                isEditing ? "Add Measurement" : "Not Set"
            }
            
            var color: Color {
                isEditing ? Color.accentColor : Color(.tertiaryLabel)
            }
            var button: some View {
                Button {
                    
                } label: {
                    Text(label)
                        .foregroundStyle(color)
                }
                .disabled(!isEditing)
            }
            
            return Group {
                if isEditing || isEmpty {
                    button
                }
            }
        }
        
        var footer: some View {
            Text(dailyValueType.description)
        }
        
        return Section(footer: footer) {
            ForEach(listData, id: \.self) {
                cell(for: $0)
                    .deleteDisabled($0.isHealth)
            }
            .onDelete(perform: delete)
            bottomContent
        }
    }
    
    func delete(at offsets: IndexSet) {

    }
}

#Preview {
    WeightForm_Past()
}
