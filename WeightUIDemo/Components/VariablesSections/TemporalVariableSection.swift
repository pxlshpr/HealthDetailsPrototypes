import SwiftUI

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
                    Text(NotSetString)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    //MARK: - Links
    
    @ViewBuilder
    var pastWeight: some View {
        if let dated = healthProvider.latest.datedWeight {
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
        if let dated = healthProvider.latest.datedLeanBodyMass {
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
        if let dated = healthProvider.latest.datedPregnancyStatus {
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
        if let dated = healthProvider.latest.datedHeight {
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

