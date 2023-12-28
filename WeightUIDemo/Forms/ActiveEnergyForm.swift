import SwiftUI

struct ActiveEnergyForm: View {

    @Environment(\.dismiss) var dismiss

    @State var value: Double? = valueForActivityLevel(.lightlyActive)
    @State var source: ActiveEnergySource = .activityLevel
    @State var activityLevel: ActivityLevel = .lightlyActive
    @State var intervalType: HealthIntervalType = .average
    @State var interval: HealthInterval = .init(3, .day)

    @State var showingAlert = false
    @State var customValue: Double? = valueForActivityLevel(.lightlyActive)
    @State var customValueTextAsDouble: Double? = valueForActivityLevel(.lightlyActive)
    @State var customValueText: String = "\(valueForActivityLevel(.lightlyActive))"
    
    @State var applyCorrection: Bool = false
    @State var correctionType: CorrectionType = .divide
    @State var correction: Double? = 2
    @State var correctionTextAsDouble: Double? = 2
    @State var correctionText: String = "2"

    @State var showingActivityLevelInfo = false
    @State var showingActiveEnergyInfo = false
    
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
            correction: $correction,
            correctionTextAsDouble: $correctionTextAsDouble,
            correctionText: $correctionText,
            setIsDirty: setIsDirty,
            isRestingEnergy: true
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
        
        var pickerSection: some View {
            
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
            
            return Section {
                Picker("Active Energy", selection: binding) {
                    ForEach(ActiveEnergySource.allCases, id: \.self) {
                        Text($0.name).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(isDisabled)
                .listRowBackground(EmptyView())
            }
            .listSectionSpacing(.compact)
        }
        
        var descriptionSection: some View {
            var description: String {
                switch source {
                case .healthKit:
                    "Use the Active Energy data recorded in the Apple Health app."
                case .activityLevel:
                    "Apply a multiplier on your Resting Energy based on how active you are."
                case .userEntered:
                    "Enter the Active Energy manually."
                }
            }
            return Section {
                Text(description)
            }
        }
        
        return Group {
            pickerSection
            descriptionSection
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
        .listSectionSpacing(.compact)
    }
    
    var customSection: some View {
        EnergyCustomSection(
            isDisabled: Binding<Bool>(
                get: { isDisabled },
                set: { _ in }
            ),
            value: $value,
            customValue: $customValue,
            customValueTextAsDouble: $customValueTextAsDouble,
            customValueText: $customValueText,
            isRestingEnergy: true,
            setIsDirty: setIsDirty,
            showingAlert: $showingAlert
        )
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
        correction = 2
        value = valueForActivityLevel(.lightlyActive)
        customValue = valueForActivityLevel(.lightlyActive)
        customValueTextAsDouble = valueForActivityLevel(.lightlyActive)
        customValueText = "\(valueForActivityLevel(.lightlyActive))"
        correctionTextAsDouble = 2
        correctionText = "2"
    }
    
    func setIsDirty() {
        isDirty = source != .activityLevel
        || activityLevel != .lightlyActive
        || intervalType != .average
        || interval != .init(3, .day)
        || applyCorrection != true
        || correctionType != .divide
        || correction != 2
        || value != valueForActivityLevel(.lightlyActive)
        || customValue != valueForActivityLevel(.lightlyActive)
        || customValueTextAsDouble != valueForActivityLevel(.lightlyActive)
        || customValueText != "\(valueForActivityLevel(.lightlyActive))"
        || correctionTextAsDouble != 2
        || correctionText != "2"
    }
    
    func submitCustomValue() {
        withAnimation {
            customValue = customValueTextAsDouble
            value = customValue
            setIsDirty()
        }
    }

    func submitCorrection() {
        withAnimation {
            correction = correctionTextAsDouble
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
