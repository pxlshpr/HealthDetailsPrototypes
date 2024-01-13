import SwiftUI

struct VariablesSections: View {
    
    @Bindable var healthProvider: HealthProvider
    
    @Binding var healthDetails: [HealthDetail]
    let date: Date
    @Binding var isPresented: Bool
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
        isPresented: Binding<Bool>,
        showHeader: Bool = true
    ) {
        self.healthProvider = healthProvider
        self.subject = subject
        _isRequired = isRequired
        _healthDetails = healthDetails
        self.date = date
        _isPresented = isPresented
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
            isPresented: $isPresented
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
            isPresented: $isPresented,
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
    
    @Bindable var healthProvider: HealthProvider

    let subject: VariablesSections.Subject
    let characteristic: HealthDetail
    let date: Date
    @Binding var isPresented: Bool

    var body: some View {
        NavigationLink {
            form
        } label: {
            label
        }
    }
    
    @ViewBuilder
    var form: some View {
        switch characteristic {
        case .age:
            AgeForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        case .sex:
            BiologicalSexForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        case .smokingStatus:
            SmokingStatusForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        default:
            EmptyView()
        }
    }
    
    var label: some View {
        HStack {
            Text(characteristic.name)
            Spacer()
            Text(healthProvider.healthDetails.valueString(for: characteristic, healthProvider.settingsProvider))
                .foregroundStyle(healthProvider.healthDetails.hasSet(characteristic) ? .primary : .secondary)
        }
    }
}

struct TemporalVariableSection: View {
    
    @Bindable var healthProvider: HealthProvider

    let subject: VariablesSections.Subject
    let healthDetail: HealthDetail
    let date: Date
    @Binding var isPresented: Bool
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
                        isPresented: $isPresented
                    )
                case .weight:
                    WeightForm(
                        healthProvider: healthProvider,
                        isPresented: $isPresented
                    )
                case .leanBodyMass:
                    LeanBodyMassForm(
                        healthProvider: healthProvider,
                        isPresented: $isPresented
                    )
                case .maintenance:
                    MaintenanceForm(
                        healthProvider: healthProvider,
                        isPresented: $isPresented
                    )
                case .preganancyStatus:
                    PregnancyStatusForm(
                        healthProvider: healthProvider,
                        isPresented: $isPresented
                    )
                default:
                    EmptyView()
                }
            }
        } label: {
            HStack {
                Text(date.shortDateString)
                Spacer()
                if healthProvider.healthDetails.hasSet(healthDetail)  {
                    Text(healthProvider.healthDetails.valueString(for: healthDetail, healthProvider.settingsProvider))
                } else {
                    Text("Not Set")
                        .foregroundStyle(.secondary)
                }
            }
        }
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
                    save: { newWeight in
                        healthProvider.updateLatestWeight(newWeight)
                    }
                )
            } label: {
                HStack {
                    Text(latestWeight.date.shortDateString)
                    Spacer()
                    Text(latestWeight.weight.valueString(in: healthProvider.settingsProvider.bodyMassUnit))
                }
            }
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
                    save: { leanBodyMass in
                        healthProvider.updateLatestLeanBodyMass(leanBodyMass)
                    }
                )
            } label: {
                HStack {
                    Text(latestLeanBodyMass.date.shortDateString)
                    Spacer()
                    Text(latestLeanBodyMass.leanBodyMass.valueString(in: healthProvider.settingsProvider.bodyMassUnit))
                }
            }
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
                    saveHandler: { maintenance in
                        healthProvider.updateLatestMaintenance(maintenance)
                    }
                )
            } label: {
                HStack {
                    Text(latest.date.shortDateString)
                    Spacer()
                    Text(latest.maintenance.valueString(in: healthProvider.settingsProvider.energyUnit))
                }
            }
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
                    save: { pregnancyStatus in
                        healthProvider.updateLatestPregnancyStatus(pregnancyStatus)
                    }
                )
            } label: {
                HStack {
                    Text(latest.date.shortDateString)
                    Spacer()
                    Text(latest.pregnancyStatus.name)
                }
            }
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
                    save: { newHeight in
                        healthProvider.updateLatestHeight(newHeight)
                    }
                )
            } label: {
                HStack {
                    Text(latestHeight.date.shortDateString)
                    Spacer()
                    Text(latestHeight.height.valueString(in: healthProvider.settingsProvider.heightUnit))
                }
            }
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
                isPresented: Binding<Bool>(
                    get: { true },
                    set: { newValue in
                    }
                ),
                showHeader: true
            )
        }
    }
}

struct GoalDemo: View {
    
    @State var isPresented: Bool = true

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
                            isPresented: $isPresented,
                            showHeader: true
                        )
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
                isPresented: Binding<Bool>(
                    get: { true },
                    set: { newValue in
                    }
                ),
                showHeader: true
            )
        }
    }
}

#Preview("Demo") {
    DemoView()
}
