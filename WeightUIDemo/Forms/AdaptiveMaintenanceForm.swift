import SwiftUI
import SwiftSugar

struct AdaptiveMaintenanceForm: View {
    
    @State var value: Double = 3225
    @State var weeks: Int = 1

    let pastDate: Date?
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    
    @Binding var isPresented: Bool
    @State var showingInfo = false
    
    init(pastDate: Date? = nil, isPresented: Binding<Bool> = .constant(true)) {
        self.pastDate = pastDate
        _isPresented = isPresented
        _isEditing = State(initialValue: pastDate == nil)
    }

    var body: some View {
        Form {
            notice
            intervalSection
            dietaryEnergyLink
            weightChangeLink
            explanation
        }
        .navigationTitle("Adaptive")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(isEditing && isPast)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingInfo) {
            AdaptiveMaintenanceInfo(weeks: $weeks)
        }
    }
    
    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: $isEditing)
        }
    }

    enum WeightChangeRoute {
        case form
    }

    enum DietaryEnergyRoute {
        case form
    }

    var weightChangeLink: some View {
        var destination: some View {
            WeightChangeForm()
        }
        
        var label: some View {
            HStack {
                Text("Weight Change")
                Spacer()
                Text("-1.42 kg")
            }
        }
        
        var NavigationViewLink: some View {
            NavigationLink(value: WeightChangeRoute.form) {
                label
            }
            .navigationDestination(for: WeightChangeRoute.self) { _ in
                destination
            }
        }
        
        var navigationViewLink: some View {
            NavigationLink {
                destination
            } label: {
                label
            }
        }
        
        return Section {
//            NavigationViewLink
            navigationViewLink
                .disabled(isPast && isEditing)
        }
    }

    var dietaryEnergyLink: some View {
        var destination: some View {
            DietaryEnergyForm(pastDate: pastDate, isPresented: $isPresented)
        }
        var label: some View {
            HStack {
                Text("Dietary Energy")
                Spacer()
                Text("3,456 kcal / day")
            }
        }
        var navigationViewLink: some View {
            NavigationLink {
                destination
            } label: {
                label
            }
        }
        
        var NavigationViewLink: some View {
            NavigationLink(value: DietaryEnergyRoute.form) {
                label
            }
            .navigationDestination(for: DietaryEnergyRoute.self) { _ in
                destination
            }
        }
        
        return Section {
//            NavigationViewLink
            navigationViewLink
                .disabled(isPast && isEditing)
        }
    }

    var intervalSection: some View {
        let binding = Binding<Int>(
            get: { weeks },
            set: { newValue in
                withAnimation {
                    weeks = newValue
                }
                
                isDirty = weeks != 1
            }
        )

        return Section("Use Data from past") {
            HStack(spacing: 3) {
                Stepper(
                    "",
                    value: binding,
                    in: 1...2
                )
                .fixedSize()
                Spacer()
                Text("\(weeks)")
                    .contentTransition(.numericText(value: Double(weeks)))
                Text("week\(weeks > 1 ? "s" : "")")
            }
            .foregroundStyle(isEditing ? .primary : .secondary)
            .disabled(!isEditing)
        }
    }
    
    var isPast: Bool {
        pastDate != nil
    }

    var toolbarContent: some ToolbarContent {
        Group {
            bottomToolbarContent(
                value: value,
                valueString: value.formattedEnergy,
                isDisabled: !isEditing,
                unitString: "kcal"
            )
            topToolbarContent(
                isEditing: $isEditing,
                isDirty: $isDirty,
                isPast: isPast,
                dismissAction: { isPresented = false },
                undoAction: undo,
                saveAction: save
            )

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
//                Button("Done") {
//                    dismiss()
//                }
//                .fontWeight(.semibold)
//            }
            ToolbarItem(placement: .principal) {
                Text("Maintenance Energy")
                    .font(.headline)
            }
        }
    }

    func save() {
        
    }
    
    func undo() {
        isDirty = false
        value = 3225
        weeks = 1
    }
    
    var isDisabled: Bool {
        isPast && !isEditing
    }
    
    var explanation: some View {
        @ViewBuilder
        var footer: some View {
            if !isDisabled {
                Button {
                    showingInfo = true
                } label: {
                    Text("Learn more…")
                        .font(.footnote)
                }
            }
        }
        
        return Section(footer: footer) {
            VStack(alignment: .leading) {
                Text("Your adaptive maintenance is a calculation of your maintenance energy using the energy balance equation.\n\nThe dietary energy you had consumed over a specified period and the resulting change in your weight is used to determine the average daily energy consumption that would have resulted in a net zero change in weight, ie. your maintenance.")
            }
        }
    }
}

#Preview("Current") {
    NavigationView {
        AdaptiveMaintenanceForm()
    }
}

#Preview("Past") {
    NavigationView {
        AdaptiveMaintenanceForm(pastDate: MockPastDate)
    }
}
