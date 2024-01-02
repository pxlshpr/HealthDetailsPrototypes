import SwiftUI
import SwiftSugar

struct AdaptiveMaintenanceForm: View {
    
    @State var value: Double? = 3225
    @State var weeks: Int = 1
    @State var dietaryEnergyInKcalPerDay: Double? = 3456
    @State var weightChangeInKg: Double? = -1.42
    
    @State var showingInfo = false

    let pastDate: Date?
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool
    
    init(
        pastDate: Date? = nil,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.pastDate = pastDate
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
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
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingInfo) {
            AdaptiveMaintenanceInfo(weeks: $weeks)
        }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isPast && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    func setDismissDisabled() {
        dismissDisabled = isPast && isEditing && isDirty
    }

    var bottomValue: some View {
        MeasurementBottomBar(
            double: $value,
            doubleString: Binding<String?>(
                get: { value?.formattedEnergy },
                set: { _ in }
            ),
            doubleUnitString: "kcal",
            isDisabled: Binding<Bool>(
                get: { !isEditing },
                set: { _ in }
            )
        )
    }
    
    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: $isEditing)
        }
    }

    var weightChangeLink: some View {
        var destination: some View {
            WeightChangeForm(
                pastDate: pastDate,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        }
        
        var label: some View {
            HStack {
                Text("Weight Change")
                Spacer()
                if let weightChangeInKg {
                    Text("\(weightChangeInKg.cleanHealth) kg")
                } else {
                    Text("Not Set")
                        .foregroundStyle(.secondary)
                }
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
            navigationViewLink
                .disabled(isPast && isEditing)
        }
    }

    var dietaryEnergyLink: some View {
        var destination: some View {
            DietaryEnergyForm(
                pastDate: pastDate,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        }
        var label: some View {
            HStack {
                Text("Dietary Energy")
                Spacer()
                if let dietaryEnergyInKcalPerDay {
                    Text("\(dietaryEnergyInKcalPerDay.formattedEnergy) kcal / day")
                } else {
                    Text("Not Set")
                        .foregroundStyle(.secondary)
                }
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
            topToolbarContent(
                isEditing: $isEditing,
                isDirty: $isDirty,
                isPast: isPast,
                dismissAction: { isPresented = false },
                undoAction: undo,
                saveAction: save
            )
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
                Text("Your Adaptive Maintenance is a calculation of your maintenance energy using the energy balance equation.\n\nThe dietary energy you had consumed over a specified period and the resulting change in your weight is used to determine the average daily energy consumption that would have resulted in a net zero change in weight, ie. your maintenance.")
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
struct DismissTest: View {
    @State var presented: Bool = false
    var body: some View {
        NavigationView {
            Form {
                Button("Present") {
                    presented = true
                }
            }
            .sheet(isPresented: $presented) {
                NavigationView {
                    AdaptiveMaintenanceForm(
                        pastDate: MockPastDate,
                        isPresented: $presented
                    )
                }
            }
        }
    }
}

#Preview("Dismiss Test") {
    DismissTest()
}

#Preview("DemoView") {
    DemoView()
}
