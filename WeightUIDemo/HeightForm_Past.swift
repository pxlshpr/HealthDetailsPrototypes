import SwiftUI
import SwiftSugar

struct HeightForm_Past: View {
    
    @Environment(\.dismiss) var dismiss

    @State var hasAppeared = false
    @State var dailyWeightType: Int = 0
    @State var value: Double = 117.4
    @State var isEditing = false
    @State var showingWeightSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if hasAppeared {
                    Form {
                        explanation
                        if !isEditing {
                            notice
                        }
//                        weightSettings
//                        if !isEditing {
//                            dailyWeightPicker
//                        }
                        list
//                        valueSection
                    }
                } else {
                    Color.clear
                }
            }
            .navigationTitle("Height")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                hasAppeared = true
            }
        }
        .sheet(isPresented: $showingWeightSettings) {
            HeightSettings(
                dailyWeightType: $dailyWeightType,
                value: $value
            )
        }
    }
    
    var controlColor: Color {
        isEditing ? Color(.label) : Color(.secondaryLabel)
    }
    
    var isDisabled: Bool {
        !isEditing
    }
    
    var dailyWeightPicker: some View {
        DailyWeightPicker(
            dailyWeightType: $dailyWeightType,
            value: $value,
            isDisabled: Binding<Bool>(
                get: { isDisabled },
                set: { _ in }
            )
        )
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
                    if isEditing {
                        Button {
                            showingWeightSettings = true
                        } label: {
                            Image(systemName: "switch.2")
                        }
                    }
                    Spacer()
                    Text("\(value.clean)")
                        .contentTransition(.numericText(value: value))
                        .font(LargeNumberFont)
                        .foregroundStyle(isDisabled ? .secondary : .primary)
                    Text("cm")
                        .font(LargeUnitFont)
//                        .foregroundStyle(.secondary)
                        .foregroundStyle(isDisabled ? .tertiary : .secondary)
                }
            }
        }
    }

    var weightSettings: some View {
        Button {
            showingWeightSettings = true
        } label: {
            Text("Weight Settings")
        }
    }
    
    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Your height may be used to:")
                Label {
                    Text("Calculate your estimated resting energy.")
                } icon: {
                    Circle()
                        .foregroundStyle(Color(.label))
                        .frame(width: 5, height: 5)
                }
                Label {
                    Text("Calculate your lean body mass.")
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
        .init(false, "9:42 am", "117.3 cm"),
        .init(true, "12:07 pm", "117.6 cm"),
        .init(false, "5:35 pm", "117.4 cm"),
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
            //TODO: Only show if multiple values are present
            Text("The latest measurement is always used.")
        }
        
        return Group {
            Section(footer: footer) {
                ForEach(listData, id: \.self) {
                    cell(for: $0)
                        .deleteDisabled($0.isHealth)
                }
                .onDelete(perform: delete)
            }
            Section {
                bottomContent
            }
        }
    }
    
    func delete(at offsets: IndexSet) {

    }
    
    var valueSection: some View {
        Section {
            HStack {
                Spacer()
                Text("\(value.clean)")
                    .contentTransition(.numericText(value: value))
                    .font(LargeNumberFont)
            }
        }
    }
}

#Preview {
    HeightForm_Past()
}
