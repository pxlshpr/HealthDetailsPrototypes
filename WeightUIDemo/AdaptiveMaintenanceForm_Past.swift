//import SwiftUI
//import SwiftSugar
//
//struct AdaptiveMaintenanceForm_Past: View {
//    
//    @Environment(\.dismiss) var dismiss
//
//    @State var hasAppeared = false
//    @State var maintenancetype: MaintenanceType = .adaptive
//    @State var value: Double = 3225
//
//    @State var weeks: Int = 1
//
//    @State var isEditing = false
//
//    var body: some View {
//        NavigationStack {
//            Group {
//                if hasAppeared {
//                    Form {
//                        if !isEditing {
//                            notice
//                        }
//                        intervalSection
//                        weightChangeLink
//                        dietaryEnergyLink
//                        explanation
//                    }
//                } else {
//                    Color.clear
//                }
//            }
//            .navigationTitle("Adaptive Maintenance")
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
//            message: "This data has been preserved to ensure any goals set on this day remain unchanged."
////            image: {
////                Image(systemName: "calendar.badge.clock")
////                    .font(.system(size: 30))
////                    .padding(5)
////            }
//        )
//    }
//    
//    var weightChangeLink: some View {
//        Section {
//            NavigationLink {
//                WeightChangeForm_Past()
//            } label: {
//                HStack {
//                    Text("Weight Change")
//                    Spacer()
//                    Text("-1.42 kg")
//                }
//            }
//            .disabled(isEditing)
//        }
//    }
//
//    var dietaryEnergyLink: some View {
//        Section {
//            NavigationLink {
//                DietaryEnergyForm(isPast: true)
//            } label: {
//                HStack {
//                    Text("Dietary Energy")
//                    Spacer()
//                    Text("3,456 kcal / day")
//                }
//            }
//            .disabled(isEditing)
//        }
//    }
//
//    var intervalSection: some View {
//        let binding = Binding<Int>(
//            get: { weeks },
//            set: { newValue in
//                withAnimation {
//                    weeks = newValue
//                }
//            }
//        )
//
//        return Section("Calculated Over") {
//            HStack(spacing: 3) {
//                Stepper(
//                    "",
//                    value: binding,
//                    in: 1...2
//                )
//                .fixedSize()
//                Spacer()
//                Text("\(weeks)")
//                    .contentTransition(.numericText(value: Double(weeks)))
//                Text("weeks")
//            }
//            .foregroundStyle(isEditing ? .primary : .secondary)
//            .disabled(!isEditing)
//        }
//    }
//    
//    var toolbarContent: some ToolbarContent {
//        Group {
//            ToolbarItem(placement: .bottomBar) {
//                HStack(alignment: .firstTextBaseline, spacing: 5) {
//                    Spacer()
//                    Text("\(value.formattedEnergy)")
//                        .contentTransition(.numericText(value: value))
//                        .font(LargeNumberFont)
//                    Text("kcal")
//                        .font(LargeUnitFont)
//                        .foregroundStyle(.secondary)
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
//            VStack(alignment: .leading) {
//                Text("Your adaptive maintenance is being calculated by comparing your weight change to the energy you consumed over the past \(weeks) week\(weeks > 1 ? "s" : "").\n\nThis utilises the energy balance equation which states that:")
//                Text("Energy In – Energy Out = Energy Balance")
//                    .font(.footnote)
//                    .padding(5)
//                    .background(
//                        RoundedRectangle(cornerRadius: 5)
//                            .foregroundStyle(Color(.systemGray5))
//                    )
//                Text("\nThis can be thought of as:")
//                Text("Dietary Energy – Expenditure = Weight Change")
//                    .font(.footnote)
//                    .padding(5)
//                    .background(
//                        RoundedRectangle(cornerRadius: 5)
//                            .foregroundStyle(Color(.systemGray5))
//                    )
//                Text("\nRearranging this, we get:")
//                Text("Expenditure = Dietary Energy - Weight Change")
//                    .font(.footnote)
//                    .padding(5)
//                    .background(
//                        RoundedRectangle(cornerRadius: 5)
//                            .foregroundStyle(Color(.systemGray5))
//                    )
//                Text("\nThis calculates the energy expenditure that–had you consumed instead of what you recorded–would have resulted in no weight change, or in other words your Maintenance Energy.")
//            }
//        }
//    }
//}
//
//#Preview {
//    AdaptiveMaintenanceForm_Past()
//}
