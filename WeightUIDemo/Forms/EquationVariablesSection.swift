import SwiftUI

struct VariablesSections: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    @Bindable var healthProvider: HealthProvider
    
    @Binding var healthDetails: [HealthDetail]
    let date: Date
    @Binding var isEditing: Bool
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool
    let showHeader: Bool
    @Binding var isRequired: Bool
    
    /// The subject that the variables are for
    enum Subject {
        case equation
        case goal
        case dailyValue
        
        var name: String {
            switch self {
            case .equation:     "calculation"
            case .goal:         "goal"
            case .dailyValue:   "daily value"
            }
        }
        
        var title: String {
            switch self {
            case .equation:     "Equation Variables"
            case .goal:         "Goal Variables"
            case .dailyValue:   "Daily Value Variables"
            }
        }
    }
    let subject: Subject
    
    init(
        subject: Subject,
        healthDetails: Binding<[HealthDetail]>,
        isRequired: Binding<Bool> = .constant(true),
        healthProvider: HealthProvider,
        date: Date,
        isEditing: Binding<Bool>,
        isPresented: Binding<Bool>,
        dismissDisabled: Binding<Bool>,
        showHeader: Bool = true
    ) {
        self.healthProvider = healthProvider
        self.subject = subject
        _isRequired = isRequired
        _healthDetails = healthDetails
        self.date = date
        _isEditing = isEditing
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        self.showHeader = showHeader
    }
    
    var body: some View {
        nonTemporalSection
        temporalSections
    }
    
    @ViewBuilder
    var mainHeader: some View {
        if showHeader {
            Text(subject.title)
                .formTitleStyle()
        }
    }
    
    func link(for characteristic: HealthDetail) -> some View {
        NonTemporalVariableLink(
            healthProvider: healthProvider,
            subject: subject,
            characteristic: characteristic,
            date: date,
            isEditing: $isEditing,
            isPresented: $isPresented,
            dismissDisabled: $dismissDisabled
        )
    }
    
    var nonTemporalSection: some View {
        @ViewBuilder
        var footer: some View {
            if isRequired {
                Text("These are required for this \(subject.name).")
            }
        }
        return Group {
            if !nonTemporalHealthDetails.isEmpty {
                Section(header: mainHeader, footer: footer) {
                    ForEach(nonTemporalHealthDetails) {
                        link(for: $0)
                    }
                }
            }
        }
    }
    
    var temporalSections: some View {
        Group {
            ForEach(Array(temporalHealthDetails.enumerated()), id: \.offset) { index, healthDetail in
                temporalVariableSection(for: healthDetail, index: index)
            }
        }
    }
    
    func temporalVariableSection(for healthDetail: HealthDetail, index: Int) -> some View {
        TemporalVariableSection(
            healthProvider: healthProvider,
            subject: subject,
            healthDetail: healthDetail,
            date: date,
            isEditing: $isEditing,
            isPresented: $isPresented,
            dismissDisabled: $dismissDisabled,
            isRequired: $isRequired,
            shouldShowMainHeader: Binding<Bool>(
                get: { nonTemporalHealthDetails.isEmpty && index == 0 },
                set: { _ in }
            ),
            showHeader: showHeader
        )
    }
    
    var nonTemporalHealthDetails: [HealthDetail] {
        healthDetails.nonTemporalHealthDetails
    }
    
    var temporalHealthDetails: [HealthDetail] {
        healthDetails.temporalHealthDetails
    }
    
    var isPast: Bool {
        date.startOfDay < Date.now.startOfDay
    }
}

struct NonTemporalVariableLink: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    @Bindable var healthProvider: HealthProvider

    let subject: VariablesSections.Subject
    let characteristic: HealthDetail
    let date: Date
    @Binding var isEditing: Bool
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    var body: some View {
        NavigationLink {
            form
        } label: {
            label
        }
        .disabled(isEditing && isLegacy)
    }
    
    @ViewBuilder
    var form: some View {
        switch characteristic {
        case .age:
            AgeForm(
                healthProvider: healthProvider,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        case .sex:
            BiologicalSexForm(
                healthProvider: healthProvider,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        case .smokingStatus:
            SmokingStatusForm(
                healthProvider: healthProvider,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
        default:
            EmptyView()
        }
    }
    
    var label: some View {
        HStack {
            Text(characteristic.name)
            Spacer()
            Text(healthProvider.healthDetails.valueString(for: characteristic, settingsProvider))
                .foregroundStyle(healthProvider.healthDetails.hasSet(characteristic) ? .primary : .secondary)
        }
    }
    
    var isLegacy: Bool {
        date.startOfDay < Date.now.startOfDay
    }
}

struct TemporalVariableSection: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    @Bindable var healthProvider: HealthProvider

    let subject: VariablesSections.Subject
    let healthDetail: HealthDetail
    let date: Date
    @Binding var isEditing: Bool
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool
    @Binding var isRequired: Bool
    @Binding var shouldShowMainHeader: Bool
    let showHeader: Bool

    var body: some View {
        Section(header: header, footer: footer) {
            pastLink
            currentLink
        }
    }
    
    @ViewBuilder
    var pastLink: some View {
        if !healthProvider.healthDetails.hasSet(healthDetail) {
            switch healthDetail {
            case .weight:           pastWeight
            case .leanBodyMass:     pastLeanBodyMass
            case .height:           pastHeight
            case .maintenance:      pastMaintenance
            case .preganancyStatus: pastPregnancyStatus
            default:                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    var currentLink: some View {
        NavigationLink {
            Group {
                switch healthDetail {
                case .height:
                    HeightForm(
                        healthProvider: healthProvider,
                        isPresented: $isPresented,
                        dismissDisabled: $dismissDisabled
                    )
                case .weight:
                    WeightForm(
                        healthProvider: healthProvider,
                        isPresented: $isPresented
//                        dismissDisabled: $dismissDisabled
                    )
                case .leanBodyMass:
                    LeanBodyMassForm(
                        healthProvider: healthProvider,
                        isPresented: $isPresented,
                        dismissDisabled: $dismissDisabled
                    )
                case .maintenance:
                    MaintenanceForm(
                        healthProvider: healthProvider,
                        isPresented: $isPresented,
                        dismissDisabled: $dismissDisabled
                    )
                    .environment(settingsProvider)
                case .preganancyStatus:
                    PregnancyStatusForm(
                        healthProvider: healthProvider,
                        isPresented: $isPresented,
                        dismissDisabled: $dismissDisabled
                    )
                    .environment(settingsProvider)
                default:
                    EmptyView()
                }
            }
        } label: {
            HStack {
                Text(date.shortDateString)
                Spacer()
                if healthProvider.healthDetails.hasSet(healthDetail)  {
                    Text(healthProvider.healthDetails.valueString(for: healthDetail, settingsProvider))
                } else {
                    Text("Not Set")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .disabled(isEditing && isLegacy)
    }
    
    //MARK: - Links
    
    @ViewBuilder
    var pastWeight: some View {
        if let latestWeight = healthProvider.latest.weight {
            NavigationLink {
                WeightForm(
                    date: latestWeight.date,
                    weight: latestWeight.weight,
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
//                    dismissDisabled: $dismissDisabled,
                    save: { newWeight in
                        healthProvider.updateLatestWeight(newWeight)
                    }
                )
                .environment(settingsProvider)
            } label: {
                HStack {
                    Text(latestWeight.date.shortDateString)
                    Spacer()
                    Text(latestWeight.weight.valueString(in: settingsProvider.bodyMassUnit))
                }
            }
            .disabled(isEditing && isLegacy)
        }
    }
    
    @ViewBuilder
    var pastLeanBodyMass: some View {
        if let latestLeanBodyMass = healthProvider.latest.leanBodyMass {
            NavigationLink {
                LeanBodyMassForm(
                    date: latestLeanBodyMass.date,
                    leanBodyMass: latestLeanBodyMass.leanBodyMass,
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled,
                    save: { leanBodyMass in
                        //TODO: Save
                        healthProvider.updateLatestLeanBodyMass(leanBodyMass)
                    }
                )
                .environment(settingsProvider)
            } label: {
                HStack {
                    Text(latestLeanBodyMass.date.shortDateString)
                    Spacer()
                    Text(latestLeanBodyMass.leanBodyMass.valueString(in: settingsProvider.bodyMassUnit))
                }
            }
            .disabled(isEditing && isLegacy)
        }
    }
    
    @ViewBuilder
    var pastMaintenance: some View {
        if let latest = healthProvider.latest.maintenance {
            NavigationLink {
                MaintenanceForm(
                    date: latest.date,
                    maintenance: latest.maintenance,
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled,
                    saveHandler: { maintenance in
                        //TODO: Save
                        healthProvider.updateLatestMaintenance(maintenance)
                    }
                )
                .environment(settingsProvider)
            } label: {
                HStack {
                    Text(latest.date.shortDateString)
                    Spacer()
                    Text(latest.maintenance.valueString(in: settingsProvider.energyUnit))
                }
            }
            .disabled(isEditing && isLegacy)
        }
    }
    
    @ViewBuilder
    var pastPregnancyStatus: some View {
        if let latest = healthProvider.latest.pregnancyStatus {
            NavigationLink {
                PregnancyStatusForm(
                    date: latest.date,
                    pregnancyStatus: latest.pregnancyStatus,
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled,
                    save: { pregnancyStatus in
                        //TODO: Save
                        healthProvider.updateLatestPregnancyStatus(pregnancyStatus)
                    }
                )
                .environment(settingsProvider)
            } label: {
                HStack {
                    Text(latest.date.shortDateString)
                    Spacer()
                    Text(latest.pregnancyStatus.name)
                }
            }
            .disabled(isEditing && isLegacy)
        }
    }
    
    @ViewBuilder
    var pastHeight: some View {
        if let latestHeight = healthProvider.latest.height {
            NavigationLink {
                HeightForm(
                    date: latestHeight.date,
                    height: latestHeight.height,
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled,
                    save: { newHeight in
                        //TODO: Save
                        healthProvider.updateLatestHeight(newHeight)
                    }
                )
            } label: {
                HStack {
                    Text(latestHeight.date.shortDateString)
                    Spacer()
                    Text(latestHeight.height.valueString(in: settingsProvider.heightUnit))
                }
            }
            .disabled(isEditing && isLegacy)
        }
    }
    
    
    //MARK: - Accessory Views
    
    @ViewBuilder
    var mainHeader: some View {
        if showHeader {
            Text(subject.title)
                .formTitleStyle()
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            if shouldShowMainHeader {
                mainHeader
            }
            Text(healthDetail.name)
        }
    }
    
    
    var footer: some View {
        var string: String? {
            guard !healthProvider.healthDetails.hasSet(healthDetail) else {
                return nil
            }
            if hasLatestDetail {
                let dateString: String
                let suffix: String
                if !date.isToday {
                    dateString = date.shortDateString
                    suffix = "prior to that "
                } else {
                    dateString = "today"
                    suffix = ""
                }
                return "Since no \(healthDetail.name.lowercased()) data has been set for \(dateString), the most recent entry \(suffix)is being used."
            } else if isRequired {
                return "Your \(healthDetail.name.lowercased()) is required for this \(subject.name)."
            } else {
                return nil
            }
        }
        
        return Group {
            if let string {
                Text(string)
            }
        }
    }

    //MARK: - Convenience
    
    var hasLatestDetail: Bool {
        switch healthDetail {
        case .weight:
            healthProvider.latest.weight != nil
        case .height:
            healthProvider.latest.height != nil
        case .leanBodyMass:
            healthProvider.latest.leanBodyMass != nil
        case .preganancyStatus:
            healthProvider.latest.pregnancyStatus != nil
        case .maintenance:
            healthProvider.latest.maintenance != nil
        default:
            false
        }
    }
        
    var isLegacy: Bool {
        date.startOfDay < Date.now.startOfDay
    }
}

#Preview("Equation") {
    NavigationView {
        Form {
            VariablesSections(
                subject: .equation,
                healthDetails: Binding<[HealthDetail]>(
                    get: { [.weight, .height, .age, .leanBodyMass, .sex] },
                    set: { _ in }
                ),
                isRequired: Binding<Bool>(
                    get: { true },
                    set: { _ in }
                ),
                healthProvider: MockCurrentProvider,
                date: Date.now,
                isEditing: .constant(false),
                isPresented: Binding<Bool>(
                    get: { true },
                    set: { newValue in
                    }
                ),
                dismissDisabled: .constant(false),
                showHeader: true
            )
            .environment(SettingsProvider())
        }
    }
}

struct GoalDemo: View {
    
    @State var isPresented: Bool = true
    @State var dismissDisabled: Bool = false

    var body: some View {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                NavigationView {
                    Form {
                        VariablesSections(
                            subject: .goal,
                            healthDetails: Binding<[HealthDetail]>(
                                get: { [.maintenance] },
                                set: { _ in }
                            ),
                            isRequired: Binding<Bool>(
                                get: { true },
                                set: { _ in }
                            ),
                            healthProvider: MockCurrentProvider,
                            date: Date.now,
                            isEditing: .constant(false),
                            isPresented: $isPresented,
                            dismissDisabled: $dismissDisabled,
                            showHeader: true
                        )
                        .environment(SettingsProvider())
                    }
                    .navigationTitle("Goal Demo")
                }
            }
    }
}

#Preview("Goal") {
    GoalDemo()
}

#Preview("Daily Value") {
    NavigationView {
        Form {
            VariablesSections(
                subject: .dailyValue,
                healthDetails: Binding<[HealthDetail]>(
                    get: { [.preganancyStatus, .smokingStatus, .age, .sex] },
                    set: { _ in }
                ),
                isRequired: Binding<Bool>(
                    get: { true },
                    set: { _ in }
                ),
                healthProvider: MockCurrentProvider,
                date: Date.now,
                isEditing: .constant(false),
                isPresented: Binding<Bool>(
                    get: { true },
                    set: { newValue in
                    }
                ),
                dismissDisabled: .constant(false),
                showHeader: true
            )
            .environment(SettingsProvider())
        }
    }
}

#Preview("Demo") {
    DemoView()
}
