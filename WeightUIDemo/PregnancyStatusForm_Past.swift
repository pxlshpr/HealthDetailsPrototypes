//import SwiftUI
//import SwiftSugar
//
//struct PregnancyStatusForm_Past: View {
//    
//    @Environment(\.dismiss) var dismiss
//
//    @State var hasAppeared = false
//    @State var pregnancyStatus: PregnancyStatus = .notPregnantOrLactating
//    @State var isEditing = false
//
//    var body: some View {
//        NavigationView {
//            Group {
//                if hasAppeared {
//                    Form {
//                        explanation
//                        if !isEditing {
//                            notice
//                        }
//                        picker
//                    }
//                } else {
//                    Color.clear
//                }
//            }
//            .navigationTitle("Pregnancy Status")
//            .navigationBarTitleDisplayMode(.large)
//            .toolbar { toolbarContent }
//        }
//        .onAppear {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//                hasAppeared = true
//            }
//        }
//    }
//    
//    var notice: some View {
//        NoticeSection(
//            style: .plain,
//            title: "Previous Data",
//            message: "This data has been preserved to ensure any goals or daily values set on this day remain unchanged."
////            image: {
////                Image(systemName: "calendar.badge.clock")
////                    .font(.system(size: 30))
////                    .padding(5)
////            }
//        )
//    }
//    
//    var isDisabled: Bool {
//        !isEditing
//    }
//
//    var picker: some View {
//        PickerSection(
//            [PregnancyStatus.notPregnantOrLactating, PregnancyStatus.pregnant, PregnancyStatus.lactating],
//            $pregnancyStatus,
//            isDisabled: Binding<Bool>(
//                get: { isDisabled },
//                set: { _ in }
//            )
//        )
//    }
//
//    var toolbarContent: some ToolbarContent {
//        var valueLabel: String {
//            pregnancyStatus.name
//        }
//        
//        return Group {
//            ToolbarItem(placement: .bottomBar) {
//                HStack(alignment: .firstTextBaseline, spacing: 5) {
//                    Spacer()
//                    Text(valueLabel)
//                        .font(NotSetFont)
//                        .foregroundStyle(pregnancyStatus == .noneOption ? .secondary : .primary)
//                }
//            }
//            ToolbarItem(placement: .topBarTrailing) {
//                Button(isEditing ? "Done" : "Edit") {
//                    if isEditing {
//                        withAnimation {
//                            isEditing = false
//                        }
//                    } else {
//                        withAnimation {
//                            isEditing = true
//                        }
//                    }
//                }
//                .fontWeight(.semibold)
//            }
//            ToolbarItem(placement: .topBarLeading) {
//                if isEditing {
//                    Button("Cancel") {
//                        withAnimation {
//                            isEditing = false
//                        }
//                    }
//                }
//            }
//        }
//    }
//
//    var explanation: some View {
//        Section {
//            Text("Your pregnancy status may be used when picking daily values for micronutrients.\n\nFor example, the recommended daily allowance for Iodine almost doubles when a mother is breastfeeding.")
//        }
//    }
//
//}
//
//#Preview {
//    PregnancyStatusForm_Past()
//}
