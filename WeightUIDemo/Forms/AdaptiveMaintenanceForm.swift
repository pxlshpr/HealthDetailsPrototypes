import SwiftUI
import SwiftSugar

struct AdaptiveMaintenanceForm: View {
    
    @State var value: Double? = 3225
    @State var weeks: Int = 1
    @State var dietaryEnergyInKcalPerDay: Double? = 3456
    @State var weightChangeInKg: Double? = -1.42
    
    @State var showingInfo = false

    let date: Date
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool
    
    init(
        date: Date = Date.now,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.date = date
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: date.isToday)
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
        .navigationBarBackButtonHidden(isLegacy && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    func setDismissDisabled() {
        dismissDisabled = isLegacy && isEditing && isDirty
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
        if isLegacy {
            NoticeSection.legacy(date, isEditing: $isEditing)
        }
    }

    var weightChangeLink: some View {
        Section {
            NavigationLink {
                WeightChangeForm(
                    date: date,
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled
                )
            } label: {
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
            .disabled(isLegacy && isEditing)
        }
    }

    var dietaryEnergyLink: some View {
        Section {
            NavigationLink {
                DietaryEnergyForm(
                    date: date,
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled
                )
            } label: {
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
            .disabled(isLegacy && isEditing)
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
    
    var isLegacy: Bool {
        date.startOfDay < Date.now.startOfDay
    }

    var toolbarContent: some ToolbarContent {
        Group {
            topToolbarContent(
                isEditing: $isEditing,
                isDirty: $isDirty,
                isPast: isLegacy,
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
        isLegacy && !isEditing
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
        AdaptiveMaintenanceForm(date: MockPastDate)
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
                        date: MockPastDate,
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
