import SwiftUI

struct EquationVariablesSections: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    @Bindable var healthProvider: HealthProvider
    
    @Binding var healthDetails: [HealthDetail]
    let pastDate: Date?
    @Binding var isEditing: Bool
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool
    let showHeader: Bool
    @Binding var isRequired: Bool
    
    init(
        healthDetails: Binding<[HealthDetail]>,
        isRequired: Binding<Bool> = .constant(true),
        healthProvider: HealthProvider,
        pastDate: Date?,
        isEditing: Binding<Bool>,
        isPresented: Binding<Bool>,
        dismissDisabled: Binding<Bool>,
        showHeader: Bool = true
    ) {
        self.healthProvider = healthProvider
        _isRequired = isRequired
        _healthDetails = healthDetails
        self.pastDate = pastDate
        _isEditing = isEditing
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        self.showHeader = showHeader
    }
    
    var body: some View {
        characteristicsSection
        measurementSections
    }
    
    @ViewBuilder
    var mainHeader: some View {
        if showHeader {
            Text("Equation Variables")
                .formTitleStyle()
        }
    }
    
    func link(for characteristic: HealthDetail) -> some View {
        Group {
            switch characteristic {
            case .age:
                NavigationLink {
                    AgeForm(healthProvider: healthProvider)
                } label: {
                    HStack {
                        Text(characteristic.name)
                        Spacer()
                        Text(healthProvider.healthDetails.valueString(for: .age, settingsProvider))
                    }
                }
            case .sex:
                NavigationLink {
                    BiologicalSexForm(healthProvider: healthProvider)
                } label: {
                    HStack {
                        Text(characteristic.name)
                        Spacer()
                        Text(healthProvider.healthDetails.valueString(for: .sex, settingsProvider))
                    }
                }
            default:
                EmptyView()
            }
        }
        .disabled(isEditing && isPast)
    }
    
    @ViewBuilder
    var characteristicsSection: some View {
        if !characteristics.isEmpty {
            Section(header: mainHeader) {
                ForEach(characteristics) {
                    link(for: $0)
                }
            }
        }
    }
    
    var measurementSections: some View {
        Group {
            ForEach(Array(measurements.enumerated()), id: \.offset) { index, healthDetail in
                measurementSection(for: healthDetail, index: index)
            }
        }
    }
    
    func measurementSection(for healthDetail: HealthDetail, index: Int) -> some View {
        EquationVariableTemporalSection(
            healthProvider: healthProvider,
            healthDetail: healthDetail,
            pastDate: pastDate,
            isEditing: $isEditing,
            isPresented: $isPresented,
            dismissDisabled: $dismissDisabled,
            isRequired: $isRequired,
            shouldShowMainHeader: Binding<Bool>(
                get: { characteristics.isEmpty && index == 0 },
                set: { _ in }
            ),
            showHeader: showHeader
        )
    }
    
//    func measurementSection(for healthDetail: HealthDetail, index: Int) -> some View {
//        
//        var header: some View {
//            let shouldShowMainHeader = characteristics.isEmpty && index == 0
//            return VStack(alignment: .leading, spacing: 10) {
//                if shouldShowMainHeader {
//                    mainHeader
//                }
//                Text(healthDetail.name)
//            }
//        }
//        
//        var formDate: Date {
//            pastDate ?? Date.now
//        }
//        
//        var hasData: Bool {
//            switch healthDetail {
//            case .weight:
//                healthProvider.latest.weight != nil
//            case .height:
//                healthProvider.latest.height != nil
//            case .leanBodyMass:
//                healthProvider.latest.leanBodyMass != nil
//            default:
//                false
//            }
//        }
//        
//        @ViewBuilder
//        var footer: some View {
//            if hasData {
//                if let pastDate, !pastDate.isToday {
//                    Text("Since no \(healthDetail.name.lowercased()) data has been set for \(pastDate.shortDateString), the most recent entry prior to that is being used.")
//                } else {
//                    Text("Since no \(healthDetail.name.lowercased()) data has been set for today, the most recent entry is being used.")
//                }
//            } else if isRequired {
//                Text("Your \(healthDetail.name.lowercased()) is required for this calculation.")
//            }
//        }
//        
//        @ViewBuilder
//        var pastLink: some View {
//            switch healthDetail {
//            case .weight:
//                if let latestWeight = healthProvider.latest.weight {
//                    NavigationLink {
//                        WeightForm(
//                            date: latestWeight.date,
//                            weight: latestWeight.weight,
//                            isPresented: $isPresented,
//                            dismissDisabled: $dismissDisabled,
//                            save: { newWeight in
//                                //TODO: Save
//                                healthProvider.updateLatestWeight(newWeight)
//                            }
//                        )
//                    } label: {
//                        HStack {
//                            Text(latestWeight.date.shortDateString)
//                            Spacer()
//                            Text(latestWeight.weight.valueString(in: settingsProvider.bodyMassUnit))
//                        }
//                    }
//                    .disabled(isEditing && isPast)
//                }
//            case .leanBodyMass:
//                if let latestLeanBodyMass = healthProvider.latest.leanBodyMass {
//                    NavigationLink {
//                        LeanBodyMassForm(
//                            date: latestLeanBodyMass.date,
//                            leanBodyMass: latestLeanBodyMass.leanBodyMass,
//                            healthProvider: healthProvider,
//                            isPresented: $isPresented,
//                            dismissDisabled: $dismissDisabled,
//                            save: { leanBodyMass in
//                                //TODO: Save
//                                healthProvider.updateLatestLeanBodyMass(leanBodyMass)
//                            }
//                        )
//                    } label: {
//                        HStack {
//                            Text(latestLeanBodyMass.date.shortDateString)
//                            Spacer()
//                            Text(latestLeanBodyMass.leanBodyMass.valueString(in: settingsProvider.bodyMassUnit))
//                        }
//                    }
//                    .disabled(isEditing && isPast)
//                }
//            case .height:
//                if let latestHeight = healthProvider.latest.height {
//                    NavigationLink {
//                        HeightForm(
//                            date: latestHeight.date,
//                            height: latestHeight.height,
//                            isPresented: $isPresented,
//                            dismissDisabled: $dismissDisabled,
//                            save: { newHeight in
//                                //TODO: Save
//                                healthProvider.updateLatestHeight(newHeight)
//                            }
//                        )
//                    } label: {
//                        HStack {
//                            Text(latestHeight.date.shortDateString)
//                            Spacer()
//                            Text(latestHeight.height.valueString(in: settingsProvider.heightUnit))
//                        }
//                    }
//                    .disabled(isEditing && isPast)
//                }
//            default:
//                EmptyView()
//            }
//        }
//        
//        @ViewBuilder
//        var currentLink: some View {
//            if !healthProvider.healthDetails.hasSet(healthDetail) {
//                NavigationLink {
//                    switch healthDetail {
//                    case .height:
//                        HeightForm(
//                            healthProvider: healthProvider,
//                            isPresented: $isPresented
//                        )
//                    case .weight:
//                        WeightForm(
//                            healthProvider: healthProvider,
//                            isPresented: $isPresented,
//                            dismissDisabled: $dismissDisabled
//                        )
//                    case .leanBodyMass:
//                        LeanBodyMassForm(
//                            healthProvider: healthProvider,
//                            isPresented: $isPresented,
//                            dismissDisabled: $dismissDisabled
//                        )
//                    default:
//                        EmptyView()
//                    }
//                } label: {
//                    HStack {
//                        Text(formDate.shortDateString)
//                        Spacer()
//                        Text("Not Set")
//                            .foregroundStyle(.secondary)
//                    }
//                }
//                .disabled(isEditing && isPast)
//            }
//        }
//        
//        return Section(header: header, footer: footer) {
//            pastLink
//            currentLink
//        }
//    }
    
    var characteristics: [HealthDetail] {
        healthDetails.nonTemporalHealthDetails
    }
    
    var measurements: [HealthDetail] {
        healthDetails.temporalHealthDetails
    }
    
    var isPast: Bool {
        pastDate != nil
    }
}

struct EquationVariableTemporalSection: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    @Bindable var healthProvider: HealthProvider

    let healthDetail: HealthDetail
    let pastDate: Date?
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
            case .weight:       pastWeight
            case .leanBodyMass: pastLeanBodyMass
            case .height:       pastHeight
            default:            EmptyView()
            }
        }
    }
    
    @ViewBuilder
    var currentLink: some View {
        NavigationLink {
            switch healthDetail {
            case .height:
                HeightForm(
                    healthProvider: healthProvider,
                    isPresented: $isPresented
                )
            case .weight:
                WeightForm(
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled
                )
            case .leanBodyMass:
                LeanBodyMassForm(
                    healthProvider: healthProvider,
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled
                )
            default:
                EmptyView()
            }
        } label: {
            HStack {
                Text(formDate.shortDateString)
                Spacer()
                if healthProvider.healthDetails.hasSet(healthDetail)  {
                    Text(healthProvider.healthDetails.valueString(for: healthDetail, settingsProvider))
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
                    isPresented: $isPresented,
                    dismissDisabled: $dismissDisabled,
                    save: { newWeight in
                        //TODO: Save
                        healthProvider.updateLatestWeight(newWeight)
                    }
                )
            } label: {
                HStack {
                    Text(latestWeight.date.shortDateString)
                    Spacer()
                    Text(latestWeight.weight.valueString(in: settingsProvider.bodyMassUnit))
                }
            }
            .disabled(isEditing && isPast)
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
            } label: {
                HStack {
                    Text(latestLeanBodyMass.date.shortDateString)
                    Spacer()
                    Text(latestLeanBodyMass.leanBodyMass.valueString(in: settingsProvider.bodyMassUnit))
                }
            }
            .disabled(isEditing && isPast)
        }
    }
    
    @ViewBuilder
    var pastHeight: some View {
        if let latestHeight = healthProvider.latest.height {
            NavigationLink {
                HeightForm(
                    date: latestHeight.date,
                    height: latestHeight.height,
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
            .disabled(isEditing && isPast)
        }
    }
    
    
    //MARK: - Accessory Views
    
    @ViewBuilder
    var mainHeader: some View {
        if showHeader {
            Text("Equation Variables")
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
                if let pastDate, !pastDate.isToday {
                    dateString = pastDate.shortDateString
                    suffix = "prior to that "
                } else {
                    dateString = "today"
                    suffix = ""
                }
                return "Since no \(healthDetail.name.lowercased()) data has been set for \(dateString), the most recent entry \(suffix)is being used."
            } else if isRequired {
                return "Your \(healthDetail.name.lowercased()) is required for this calculation."
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
    
    var formDate: Date {
        pastDate ?? Date.now
    }
    
    var hasLatestDetail: Bool {
        switch healthDetail {
        case .weight:
            healthProvider.latest.weight != nil
        case .height:
            healthProvider.latest.height != nil
        case .leanBodyMass:
            healthProvider.latest.leanBodyMass != nil
        default:
            false
        }
    }
        
    var isPast: Bool {
        pastDate != nil
    }
}
