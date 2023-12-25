import SwiftUI
import SwiftSugar

struct SmokingStatusForm_Past: View {
    
    @Environment(\.dismiss) var dismiss

    @State var hasAppeared = false
    @State var smokingStatus: SmokingStatus = .nonSmoker
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
                        picker
                    }
                } else {
                    Color.clear
                }
            }
            .navigationTitle("Smoking Status")
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
        NoticeSection(
            style: .plain,
            title: "Previous Data",
            message: "This data has been preserved to ensure any goals or daily values set on this day remain unchanged."
//            image: {
//                Image(systemName: "calendar.badge.clock")
//                    .font(.system(size: 30))
//                    .padding(5)
//            }
        )
    }
    
    var isDisabled: Bool {
        !isEditing
    }

    var picker: some View {
        PickerSection(
            [SmokingStatus.nonSmoker, SmokingStatus.smoker],
            $smokingStatus,
            isDisabled: Binding<Bool>(
                get: { isDisabled },
                set: { _ in }
            )
        )
    }

    var toolbarContent: some ToolbarContent {
        var smokingStatusLabel: String {
            smokingStatus.name
        }
        
        return Group {
            ToolbarItem(placement: .bottomBar) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Spacer()
                    Text(smokingStatusLabel)
                        .font(NotSetFont)
                        .foregroundStyle(smokingStatus == .noneOption ? .secondary : .primary)
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

    var explanation: some View {
        Section {
            Text("Your smoking status may be used when picking daily values for micronutrients.\n\nFor example, if you are a smoker then the recommended daily intake of Vitamin C will be slightly higher.")
        }
    }

}

#Preview {
    SmokingStatusForm_Past()
}
