import SwiftUI

struct ActiveEnergyForm: View {

    @State var value: Double? = valueForActivityLevel(.lightlyActive)
    @State var source: ActiveEnergySource = .activityLevel
    @State var activityLevel: ActivityLevel = .lightlyActive
    @State var intervalType: HealthIntervalType = .average
    @State var interval: HealthInterval = .init(3, .day)

    @State var showingAlert = false
    
    @State var customInput = DoubleInput(double: valueForActivityLevel(.lightlyActive))

    @State var applyCorrection: Bool = false
    @State var correctionType: CorrectionType = .divide
    @State var correctionInput = DoubleInput(double: 2)

    @State var showingActivityLevelInfo = false
    @State var showingActiveEnergyInfo = false
    @State var showingCorrectionAlert = false

    let pastDate: Date?
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool

    init(pastDate: Date? = nil, isPresented: Binding<Bool> = .constant(true)) {
        self.pastDate = pastDate
        _isPresented = isPresented
        _isEditing = State(initialValue: pastDate == nil)
    }

    var body: some View {
        Form {
            notice
            explanation
            sourceSection
            switch source {
            case .userEntered:
                customSection
            case .activityLevel:
                activityLevelSection
            case .healthKit:
                healthSections
            }
        }
        .navigationTitle("Active Energy")
        .navigationBarBackButtonHidden(isEditing && isPast)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingActivityLevelInfo) {
            ActivityLevelInfo()
        }
        .sheet(isPresented: $showingActiveEnergyInfo) {
            ActiveEnergyInfo()
        }
        .alert("Enter your Active Energy", isPresented: $showingAlert) {
            TextField("kcal", text: customInput.binding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCustomValue)
            Button("Cancel") { 
                customInput.cancel()
            }
        }
        .alert("Enter a correction", isPresented: $showingCorrectionAlert) {
            TextField(correctionType.textFieldPlaceholder, text: correctionInput.binding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCorrection)
            Button("Cancel") { correctionInput.cancel() }
        }
    }
    
    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: $isEditing)
        }
    }

    var healthSections: some View {
        EnergyAppleHealthSections(
            intervalType: $intervalType,
            interval: $interval,
            pastDate: pastDate,
            isEditing: $isEditing,
            applyCorrection: $applyCorrection,
            correctionType: $correctionType,
            correctionInput: $correctionInput,
            setIsDirty: setIsDirty,
            isRestingEnergy: true,
            showingCorrectionAlert: $showingCorrectionAlert
        )
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            bottomToolbarContent(
                value: value,
                valueString: value?.formattedEnergy,
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
        }
    }
    
    var isDisabled: Bool {
        isPast && !isEditing
    }
    
    var controlColor: Color {
        isDisabled ? .secondary : .primary
    }
    
    var isPast: Bool {
        pastDate != nil
    }
    
    var activityLevelSection: some View {
        let binding = Binding<ActivityLevel>(
            get: { activityLevel },
            set: { newValue in
                withAnimation {
                    activityLevel = newValue
                    value = valueForActivityLevel(newValue)
                    setIsDirty()
                }
            }
        )
        
        @ViewBuilder
        var footer: some View {
            Button {
                showingActivityLevelInfo = true
            } label: {
                Text("Learn more…")
                    .font(.footnote)
            }
        }

        return Section(footer: footer) {
            Picker("Activity Level", selection: binding) {
                ForEach(ActivityLevel.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.menu)
            .foregroundStyle(controlColor)
            .disabled(isDisabled)
        }
    }
    
    var sourceSection: some View {
        
        var pickerRow: some View {
            
            let binding = Binding<ActiveEnergySource>(
                get: { source },
                set: { newValue in
                    withAnimation {
                        source = newValue
                        setIsDirty()
                    }
                    if source == .userEntered {
                        showingAlert = true
                    }
                }
            )
            
            return Picker("Active Energy", selection: binding) {
                ForEach(ActiveEnergySource.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .disabled(isDisabled)
            .listRowSeparator(.hidden)
        }
        
        var descriptionRow: some View {
            var description: String {
                switch source {
                case .healthKit:
                    "Use the Active Energy data recorded in the Apple Health app."
                case .activityLevel:
                    "Apply a multiplier on your Resting Energy based on how active you are."
                case .userEntered:
                    "Enter your Active Energy manually."
                }
            }
            return Text(description)
        }
        
        return Section {
            pickerRow
            descriptionRow
        }
    }
    
    var explanation: some View {
        var header: some View {
            Text("About Active Energy")
                .textCase(.none)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(Color(.label))
        }
        
        var footer: some View {
            Button {
                showingActiveEnergyInfo = true
            } label: {
                Text("Learn more…")
                    .font(.footnote)
            }
        }
        
        return Section {
            VStack(alignment: .leading) {
                Text("This is the energy burnt over and above your Resting Energy use. You can set it in three ways.")
            }
        }
    }
    
    @ViewBuilder
    var customSection: some View {
        if !isDisabled {
            Section {
                Button {
                    showingAlert = true
                } label: {
                    Text("\(value != nil ? "Edit" : "Set") Active Energy")
                }
            }
        }
    }
}

//MARK: - Actions

extension ActiveEnergyForm {
    func undo() {
        isDirty = false
        source = .activityLevel
        activityLevel = .lightlyActive
        intervalType = .average
        interval = .init(3, .day)
        applyCorrection = true
        correctionType = .divide
        value = valueForActivityLevel(.lightlyActive)
        customInput = DoubleInput(double: valueForActivityLevel(.lightlyActive))
        correctionInput = DoubleInput(double: 2)
    }
    
    func setIsDirty() {
        isDirty = source != .activityLevel
        || activityLevel != .lightlyActive
        || intervalType != .average
        || interval != .init(3, .day)
        || applyCorrection != true
        || correctionType != .divide
        || value != valueForActivityLevel(.lightlyActive)
        || correctionInput.double != 2
    }
    
    func submitCustomValue() {
        withAnimation {
            customInput.submitValue()
            value = customInput.double
            setIsDirty()
        }
    }

    func submitCorrection() {
        withAnimation {
            correctionInput.submitValue()
            setIsDirty()
        }
    }
    
    func save() {
        
    }
}

#Preview("Current") {
    NavigationView {
        ActiveEnergyForm()
    }
}

#Preview("Past") {
    NavigationView {
        ActiveEnergyForm(pastDate: MockPastDate)
    }
}
