import SwiftUI

struct VariablesSections: View {
    
    @Bindable var healthProvider: HealthProvider
    
    @Binding var variables: Variables
    let date: Date
    @Binding var isPresented: Bool
    let showHeader: Bool
    
    /// The type that the variables are for
    let type: VariablesType
    
    var preferLeanBodyMass: Binding<Bool>?
    
    init(
        type: VariablesType,
        variables: Binding<Variables>,
        preferLeanBodyMass: Binding<Bool>? = nil,
        healthProvider: HealthProvider,
        date: Date,
        isPresented: Binding<Bool>,
        showHeader: Bool = true
    ) {
        self.healthProvider = healthProvider
        self.type = type
        self.preferLeanBodyMass = preferLeanBodyMass
        self.date = date
        self.showHeader = showHeader
        _variables = variables
        _isPresented = isPresented
    }
    
    var body: some View {
        explanation
        leanBodyMassPicker
        nonTemporalSection
        temporalSections
    }
    
    var leanBodyMassPicker: some View {
        
        var shouldShow: Bool {
            variables.isLeanBodyMass
            && preferLeanBodyMass != nil
            && healthProvider.healthDetails.hasIncompatibleLeanBodyMassAndFatPercentageWithWeight
        }
        
        let binding = Binding<Bool>(
            get: { preferLeanBodyMass?.wrappedValue ?? true },
            set: {
                preferLeanBodyMass?.wrappedValue = $0
            }
        )
        
        return Group {
            if shouldShow {
                Section {
                    Picker("Use", selection: binding) {
                        Text("Lean Body Mass").tag(true)
                        Text("Fat Percentage and Weight").tag(false)
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }
    
    var explanation: some View {
        var header: some View {
            Text(type.title)
                .formTitleStyle()
        }
        
        return Section(header: header) {
            Text(variables.description)
        }
    }
    
    var nonTemporalSection: some View {
        
        func link(for healthDetail: HealthDetail) -> some View {
            NonTemporalVariableLink(
                healthDetail: healthDetail,
                healthProvider: healthProvider,
                date: date,
                isPresented: $isPresented
            )
        }
        
        return Group {
            if !variables.nonTemporal.isEmpty {
//                Section(header: mainHeader) {
                Section {
                    ForEach(variables.nonTemporal) {
                        link(for: $0)
                    }
                }
            }
        }
    }
    
    var temporalSections: some View {
        func section(for healthDetail: HealthDetail, index: Int) -> some View {
            TemporalVariableSection(
                healthDetail: healthDetail,
                healthProvider: healthProvider,
                type: type,
                date: date,
                isPresented: $isPresented,
                shouldShowMainHeader: Binding<Bool>(
                    get: { variables.nonTemporal.isEmpty && index == 0 },
                    set: { _ in }
                ),
                showHeader: showHeader
            )
        }
        
        return Group {
            ForEach(Array(variables.temporal.enumerated()), id: \.offset) { index, healthDetail in
                section(for: healthDetail, index: index)
                
                /// Special case for `.leanBodyMass` where we insert an "or" after the section for lean body mass
                if variables.isLeanBodyMass, healthDetail == .leanBodyMass {
                    Section {
                        HStack {
                            VStack {
                                Divider()
                            }
                            Text("or")
                            VStack {
                                Divider()
                            }
                        }
                        .listRowBackground(EmptyView())
                    }
                    .listSectionSpacing(.compact)
                }
            }
        }
    }
}

import SwiftUI

struct TemporalVariableSection: View {
    
    let healthDetail: HealthDetail
    @Bindable var healthProvider: HealthProvider

    let type: VariablesType
    let date: Date
    @Binding var isPresented: Bool
    @Binding var shouldShowMainHeader: Bool
    let showHeader: Bool

    //MARK: - Links
    @State var replacements: HealthDetails.ReplacementsForMissing?
    @State var newReplacements: HealthDetails.ReplacementsForMissing? = nil

    init(
        healthDetail: HealthDetail,
        healthProvider: HealthProvider,
        type: VariablesType,
        date: Date,
        isPresented: Binding<Bool>,
        shouldShowMainHeader: Binding<Bool>,
        showHeader: Bool
    ) {
        self.healthDetail = healthDetail
        self.healthProvider = healthProvider
        self.type = type
        self.date = date
        _isPresented = isPresented
        _shouldShowMainHeader = shouldShowMainHeader
        self.showHeader = showHeader
        _replacements = State(initialValue: healthProvider.healthDetails.replacementsForMissing)
    }

    var body: some View {
        Section(header: header, footer: footer) {
            pastLink
            currentLink
        }
        .onChange(of: healthProvider.healthDetails.replacementsForMissing, replacementsChanged)
    }
    
    func replacementsChanged(old: HealthDetails.ReplacementsForMissing, new: HealthDetails.ReplacementsForMissing) {
        if hasPushedForm {
            newReplacements = new
        } else {
            newReplacements = nil
            withAnimation {
                replacements = new
            }
        }
    }
    
    func formDisappeared() {
        withAnimation {
            replacements = newReplacements
        }
        newReplacements = nil
        hasPushedForm = false
    }
    
    func formAppeared() {
        hasPushedForm = true
    }
    
    @ViewBuilder
    var pastLink: some View {
        if !healthProvider.healthDetails.hasSet(healthDetail) {
            switch healthDetail {
            case .weight:           pastWeight
            case .leanBodyMass:     pastLeanBodyMass
            case .height:           pastHeight
            case .preganancyStatus: pastPregnancyStatus
            case .fatPercentage:    pastFatPercentage
            case .maintenance:      pastMaintenance
            default:                EmptyView()
            }
        }
    }
    
    @State var hasPushedForm = false
    
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
                case .preganancyStatus:
                    PregnancyStatusForm(
                        healthProvider: healthProvider,
                        isPresented: $isPresented
                    )
                case .fatPercentage:
                    FatPercentageForm(
                        healthProvider: healthProvider,
                        isPresented: $isPresented
                    )
                case .maintenance:
                    MaintenanceForm(
                        healthProvider: healthProvider,
                        isPresented: $isPresented
                    )
                default:
                    EmptyView()
                }
            }
            .onDisappear(perform: formDisappeared)
            .onAppear(perform: formAppeared)
        } label: {
            HStack {
                Text(date.shortDateString)
                Spacer()
                if healthProvider.healthDetails.hasSet(healthDetail)  {
                    Text(healthProvider.healthDetails.valueString(for: healthDetail, healthProvider.settingsProvider))
                } else {
                    Text(NotSetString)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    var pastWeight: some View {
        if let dated = replacements?.datedWeight {
            NavigationLink {
                WeightForm(
                    date: dated.date,
                    weight: dated.weight,
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    save: { newWeight in
                        healthProvider.updateLatestWeight(newWeight)
                    }
                )
                .onAppear(perform: formAppeared)
                .onDisappear(perform: formDisappeared)
            } label: {
                HStack {
                    Text(dated.date.shortDateString)
                    Spacer()
                    Text(dated.weight.valueString(in: healthProvider.settingsProvider.bodyMassUnit))
                }
            }
        }
    }
    
    @ViewBuilder
    var pastLeanBodyMass: some View {
        if let dated = replacements?.datedLeanBodyMass {
            NavigationLink {
                LeanBodyMassForm(
                    date: dated.date,
                    leanBodyMass: dated.leanBodyMass,
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    save: { leanBodyMass in
                        healthProvider.updateLatestLeanBodyMass(leanBodyMass)
                    }
                )
                .onAppear(perform: formAppeared)
                .onDisappear(perform: formDisappeared)
            } label: {
                HStack {
                    Text(dated.date.shortDateString)
                    Spacer()
                    Text(dated.leanBodyMass.valueString(in: healthProvider.settingsProvider.bodyMassUnit))
                }
            }
        }
    }
    
    @ViewBuilder
    var pastFatPercentage: some View {
        if let dated = replacements?.datedFatPercentage {
            NavigationLink {
                FatPercentageForm(
                    date: dated.date,
                    fatPercentage: dated.fatPercentage,
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    save: { fatPercentage in
                        healthProvider.updateLatestFatPercentage(fatPercentage)
                    }
                )
                .onAppear(perform: formAppeared)
                .onDisappear(perform: formDisappeared)
            } label: {
                HStack {
                    Text(dated.date.shortDateString)
                    Spacer()
                    Text(dated.fatPercentage.valueString)
                }
            }
        }
    }
    
    @ViewBuilder
    var pastMaintenance: some View {
        if let dated = replacements?.datedMaintenance {
            NavigationLink {
                MaintenanceForm(
                    date: dated.date,
                    maintenance: dated.maintenance,
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    saveHandler: { maintenance, shouldResync in
                        healthProvider.updateLatestMaintenance(maintenance)
                    }
                )
                .onAppear(perform: formAppeared)
                .onDisappear(perform: formDisappeared)
            } label: {
                HStack {
                    Text(dated.date.shortDateString)
                    Spacer()
                    Text(dated.maintenance.valueString(in: healthProvider.settingsProvider.energyUnit))
                }
            }
        }
    }
    
    @ViewBuilder
    var pastPregnancyStatus: some View {
        if let dated = replacements?.datedPregnancyStatus {
            NavigationLink {
                PregnancyStatusForm(
                    date: dated.date,
                    pregnancyStatus: dated.pregnancyStatus,
                    isPresented: $isPresented,
                    save: { pregnancyStatus in
                        healthProvider.updateLatestPregnancyStatus(pregnancyStatus)
                    }
                )
                .onAppear(perform: formAppeared)
                .onDisappear(perform: formDisappeared)
            } label: {
                HStack {
                    Text(dated.date.shortDateString)
                    Spacer()
                    Text(dated.pregnancyStatus.name)
                }
            }
        }
    }
    
    @ViewBuilder
    var pastHeight: some View {
        if let dated = replacements?.datedHeight {
            NavigationLink {
                HeightForm(
                    date: dated.date,
                    height: dated.height,
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    save: { newHeight in
                        healthProvider.updateLatestHeight(newHeight)
                    }
                )
                .onAppear(perform: formAppeared)
                .onDisappear(perform: formDisappeared)
            } label: {
                HStack {
                    Text(dated.date.shortDateString)
                    Spacer()
                    Text(dated.height.valueString(in: healthProvider.settingsProvider.heightUnit))
                }
            }
        }
    }
    
    
    //MARK: - Accessory Views

    var header: some View {
        Text(healthDetail.name)
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

    var hasLatestDetail: Bool {
        healthProvider.healthDetails.replacementsForMissing.has(healthDetail)
    }
}

import SwiftUI

struct NonTemporalVariableLink: View {
    
    let healthDetail: HealthDetail
    @Bindable var healthProvider: HealthProvider
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
        switch healthDetail {
        case .age:
            AgeForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        case .biologicalSex:
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
            Text(healthDetail.name)
            Spacer()
            Text(healthProvider.healthDetails.valueString(
                for: healthDetail,
                healthProvider.settingsProvider
            ))
            .foregroundStyle(healthProvider.healthDetails.hasSet(healthDetail)
                             ? .primary : .secondary
            )
        }
    }
}

struct RestingEnergyEquationVariablesSectionsPreview: View {
    
    @State var healthProvider: HealthProvider? = nil
    @State var equation: RestingEnergyEquation = .katchMcardle
//    @State var variables: Variables = RestingEnergyEquation.cunningham.variables
    
    @State var preferLeanBodyMass: Bool = false
    
    @ViewBuilder
    var body: some View {
        if let healthProvider {
            NavigationView {
                Form {
                    Section(header: Text("Equation")) {
                        Picker("", selection: $equation) {
                            ForEach(RestingEnergyEquation.allCases, id: \.self) {
                                Text($0.name).tag($0)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    VariablesSections(
                        type: .equation,
                        variables: Binding<Variables>(
                            get: { equation.variables },
                            set: { _ in }
                        ),
                        preferLeanBodyMass: Binding<Bool>(
                            get: { preferLeanBodyMass },
                            set: { newValue in
                                self.preferLeanBodyMass = newValue
                            }
                        ),
                        healthProvider: healthProvider,
                        date: healthProvider.healthDetails.date,
                        isPresented: .constant(true),
                        showHeader: true
                    )
                }
            }
        } else {
            Color.clear
                .task {
//                    var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(Date.now)
                    var healthDetails = HealthDetails(date: Date.now)
                    healthDetails.weight = .init(
                        weightInKg: 95,
                        measurements: [.init(date: Date.now, weightInKg: 95)]
                    )
                    healthDetails.leanBodyMass = .init(
                        leanBodyMassInKg: 69,
                        measurements: [.init(date: Date.now, leanBodyMassInKg: 69, source: .manual, healthKitUUID: nil)]
                    )
                    healthDetails.fatPercentage = .init(
                        fatPercentage: 20,
                        measurements: [.init(date: Date.now, percent: 20, source: .manual, healthKitUUID: nil)]
                    )
                    let settings = await fetchSettingsFromDocuments()
                    let healthProvider = HealthProvider(
                        healthDetails: healthDetails,
                        settingsProvider: SettingsProvider(settings: settings)
                    )
                    await MainActor.run {
                        self.healthProvider = healthProvider
                    }
                }
        }
    }
}
#Preview("Resting") {
    RestingEnergyEquationVariablesSectionsPreview()
}

struct LeanBodyMassEquationVariablesSectionsPreview: View {
    
    @State var healthProvider: HealthProvider? = nil
    @State var equation: LeanBodyMassAndFatPercentageEquation = .boer
//    @State var variables: Variables = RestingEnergyEquation.cunningham.variables
    
    @ViewBuilder
    var body: some View {
        if let healthProvider {
            NavigationView {
                Form {
                    Section(header: Text("Equation")) {
                        Picker("", selection: $equation) {
                            ForEach(LeanBodyMassAndFatPercentageEquation.allCases, id: \.self) {
                                Text($0.name).tag($0)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    VariablesSections(
                        type: .equation,
                        variables: Binding<Variables>(
                            get: { equation.variables },
                            set: { _ in }
                        ),
                        healthProvider: healthProvider,
                        date: healthProvider.healthDetails.date,
                        isPresented: .constant(true),
                        showHeader: true
                    )
                }
            }
        } else {
            Color.clear
                .task {
                    var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(Date.now)
                    healthDetails.weight = .init(
                        weightInKg: 95,
                        measurements: [.init(date: Date.now, weightInKg: 95)]
                    )
                    let settings = await fetchSettingsFromDocuments()
                    let healthProvider = HealthProvider(
                        healthDetails: healthDetails,
                        settingsProvider: SettingsProvider(settings: settings)
                    )
                    await MainActor.run {
                        self.healthProvider = healthProvider
                    }
                }
        }
    }
}
#Preview("Lean Body Mass") {
    LeanBodyMassEquationVariablesSectionsPreview()
}

struct GoalVariablesSectionsPreview: View {
    
    @State var healthProvider: HealthProvider? = nil
    
    @ViewBuilder
    var body: some View {
        if let healthProvider {
            NavigationView {
                Form {
                    VariablesSections(
                        type: .goal,
                        variables: Binding<Variables>(
                            get: { .required([.maintenance], "Your Maintenance Energy is required for this goal.") },
                            set: { _ in }
                        ),
                        healthProvider: healthProvider,
                        date: healthProvider.healthDetails.date,
                        isPresented: .constant(true),
                        showHeader: true
                    )
                }
            }
        } else {
            Color.clear
                .task {
                    var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(Date.now)
                    healthDetails.weight = .init(
                        weightInKg: 95,
                        measurements: [.init(date: Date.now, weightInKg: 95)]
                    )
                    healthDetails.replacementsForMissing = .init(
                        datedMaintenance: .init(
                            date: Date.now.moveDayBy(-1),
                            maintenance: .init(
                                type: .estimated,
                                kcal: 2000,
                                adaptive: .init(),
                                estimate: .init(
                                    kcal: 2000,
                                    restingEnergy: HealthDetails.Maintenance.Estimate.RestingEnergy(
                                        kcal: 1800,
                                        source: .manual
                                    ),
                                    activeEnergy: HealthDetails.Maintenance.Estimate.ActiveEnergy(
                                        kcal: 200,
                                        source: .manual
                                    )
                                ),
                                useEstimateAsFallback: false
                            )
                        )
                    )
                    let settings = await fetchSettingsFromDocuments()
                    let healthProvider = HealthProvider(
                        healthDetails: healthDetails,
                        settingsProvider: SettingsProvider(settings: settings)
                    )
                    await MainActor.run {
                        self.healthProvider = healthProvider
                    }
                }
        }
    }
}
#Preview("Goal") {
    GoalVariablesSectionsPreview()
}

struct DailyValueVariablesSectionsPreview: View {
    
    @State var healthProvider: HealthProvider? = nil
    
    @ViewBuilder
    var body: some View {
        if let healthProvider {
            NavigationView {
                Form {
                    VariablesSections(
                        type: .dailyValue,
                        variables: Binding<Variables>(
                            get: { .required([.smokingStatus], "Your Smoking Status is required to pick a recommended daily value for Magnesium.") },
                            set: { _ in }
                        ),
                        healthProvider: healthProvider,
                        date: healthProvider.healthDetails.date,
                        isPresented: .constant(true),
                        showHeader: true
                    )
                }
            }
        } else {
            Color.clear
                .task {
                    var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(Date.now)
                    healthDetails.weight = .init(
                        weightInKg: 95,
                        measurements: [.init(date: Date.now, weightInKg: 95)]
                    )
                    let settings = await fetchSettingsFromDocuments()
                    let healthProvider = HealthProvider(
                        healthDetails: healthDetails,
                        settingsProvider: SettingsProvider(settings: settings)
                    )
                    await MainActor.run {
                        self.healthProvider = healthProvider
                    }
                }
        }
    }
}
#Preview("Daily Value") {
    DailyValueVariablesSectionsPreview()
}

#Preview("Demo") {
    DemoView()
}

