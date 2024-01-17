import SwiftUI

enum Variables {
    case required([HealthDetail], String)
    case either(HealthDetail, HealthDetail, String)
    
    var temporal: [HealthDetail] {
        switch self {
        case .required(let array, _):
            return array.temporalHealthDetails
        case .either(let healthDetail, let healthDetail2, _):
            guard healthDetail.isTemporal, healthDetail2.isTemporal else {
                return []
            }
            return [healthDetail, healthDetail2]
        }
    }
    
    var nonTemporal: [HealthDetail] {
        switch self {
        case .required(let array, _):
            return array.nonTemporalHealthDetails
        case .either(let healthDetail, let healthDetail2, _):
            guard healthDetail.isNonTemporal, healthDetail2.isNonTemporal else {
                return []
            }
            return [healthDetail, healthDetail2]
        }
    }
    
    var description: String {
        switch self {
        case .required(_, let string):  string
        case .either(_, _, let string): string
        }
    }
}

struct VariablesSections: View {
    
    @Bindable var healthProvider: HealthProvider
    
    @Binding var variables: Variables
    let date: Date
    @Binding var isPresented: Bool
    let showHeader: Bool
    
    /// The type that the variables are for
    let type: VariablesType
    
    init(
        type: VariablesType,
        variables: Binding<Variables>,
        healthProvider: HealthProvider,
        date: Date,
        isPresented: Binding<Bool>,
        showHeader: Bool = true
    ) {
        self.healthProvider = healthProvider
        self.type = type
        _variables = variables
        self.date = date
        _isPresented = isPresented
        self.showHeader = showHeader
    }
    
    var body: some View {
        explanation
        nonTemporalSection
        temporalSections
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
            ForEach(Array(variables.temporal.enumerated()), id: \.offset) { index, variable in
                section(for: variable, index: index)
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
            case .preganancyStatus: pastPregnancyStatus
            case .fatPercentage:    pastFatPercentage
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
                    Text(NotSetString)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    //MARK: - Links
    
    @ViewBuilder
    var pastWeight: some View {
        if let dated = healthProvider.healthDetails.replacementsForMissing.datedWeight {
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
        if let dated = healthProvider.healthDetails.replacementsForMissing.datedLeanBodyMass {
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
        if let dated = healthProvider.healthDetails.replacementsForMissing.datedFatPercentage {
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
            } label: {
                HStack {
                    Text(dated.date.shortDateString)
                    Spacer()
                    Text(dated.fatPercentage.valueString)
                }
            }
        }
    }
//    @ViewBuilder
//    var pastMaintenance: some View {
//        if let (date, maintenance) = healthProvider.latest.maintenanceWithDate {
//            NavigationLink {
//                MaintenanceForm(
//                    date: date,
//                    maintenance: maintenance,
//                    healthProvider: healthProvider,
//                    isPresented: $isPresented,
//                    saveHandler: { maintenance in
//                        healthProvider.updateLatestMaintenance(maintenance)
//                    }
//                )
//            } label: {
//                HStack {
//                    Text(date.shortDateString)
//                    Spacer()
//                    Text(maintenance.valueString(in: healthProvider.settingsProvider.energyUnit))
//                }
//            }
//        }
//    }
    
    @ViewBuilder
    var pastPregnancyStatus: some View {
        if let dated = healthProvider.healthDetails.replacementsForMissing.datedPregnancyStatus {
            NavigationLink {
                PregnancyStatusForm(
                    date: dated.date,
                    pregnancyStatus: dated.pregnancyStatus,
                    isPresented: $isPresented,
                    save: { pregnancyStatus in
                        healthProvider.updateLatestPregnancyStatus(pregnancyStatus)
                    }
                )
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
        if let dated = healthProvider.healthDetails.replacementsForMissing.datedHeight {
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
    
//    @ViewBuilder
//    var mainHeader: some View {
//        if showHeader {
//            Text(type.title)
//                .formTitleStyle()
//        }
//    }

    var header: some View {
//        VStack(alignment: .leading, spacing: 10) {
//            if shouldShowMainHeader {
//                mainHeader
//            }
            Text(healthDetail.name)
//        }
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
//            } else if isRequired {
//                return "Your \(healthDetail.name.lowercased()) is required for this \(type.name)."
            } else {
//                return "Your \(healthDetail.name.lowercased()) is required for this \(type.name)."
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
        case .maintenance:
            MaintenanceForm(
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

#Preview("Demo") {
    DemoView()
}

enum VariablesType {
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
