import SwiftUI
import SwiftSugar

struct SexForm_Past: View {
    
    @Environment(\.dismiss) var dismiss

    @State var hasAppeared = false
    @State var sex: Sex = .male
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
                        picker
                    }
                } else {
                    Color.clear
                }
            }
            .navigationTitle("Biological Sex")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                hasAppeared = true
            }
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
            message: "This data has been preserved to ensure any goals or daily values set on this day remain unchanged.",
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
            ToolbarItem(placement: .bottomBar) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Spacer()
                    Text(sex != .other ? sex.name : "Not Set")
                        .font(NotSetFont)
                        .foregroundStyle(sex != .other ? (isDisabled ? .secondary : .primary) : (isDisabled ? .tertiary : .secondary))
                }
            }
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
        }
    }

    var weightSettings: some View {
        Button {
            showingWeightSettings = true
        } label: {
            Text("Weight Settings")
        }
    }
    
    var isDisabled: Bool {
        !isEditing
    }

    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Your biological sex may be used when:")
                Label {
                    Text("Calculating your estimated resting energy or lean body mass.")
                } icon: {
                    Circle()
                        .foregroundStyle(Color(.label))
                        .frame(width: 5, height: 5)
                }
                Label {
                    Text("Picking daily values for micronutrients.")
                } icon: {
                    Circle()
                        .foregroundStyle(Color(.label))
                        .frame(width: 5, height: 5)
                }
            }
        }
    }
    
    var picker: some View {
        PickerSection(
            [Sex.female, Sex.male],
            $sex,
            isDisabled: Binding<Bool>(
                get: { isDisabled },
                set: { _ in }
            )
        )
    }
}

#Preview {
    SexForm_Past()
}
