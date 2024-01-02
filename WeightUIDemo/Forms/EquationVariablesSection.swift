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
        NavigationLink {
            switch characteristic {
            case .age:  AgeForm(healthProvider: healthProvider)
            case .sex:  BiologicalSexForm(healthProvider: healthProvider)
            default:    EmptyView()
            }
        } label: {
            HStack {
                Text(characteristic.name)
                Spacer()
                switch characteristic {
                case .age:  Text("36 years")
                case .sex:  Text("Male")
                default:    EmptyView()
                }
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
        
        var header: some View {
            let shouldShowMainHeader = characteristics.isEmpty && index == 0
            return VStack(alignment: .leading, spacing: 10) {
                if shouldShowMainHeader {
                    mainHeader
                }
                Text(healthDetail.name)
            }
        }
        
        var formDate: Date {
            pastDate ?? Date.now
        }
        
        var hasData: Bool {
            switch healthDetail {
            case .weight:
                healthProvider.latest.weight != nil
            default:
                false
            }
        }
        
        @ViewBuilder
        var footer: some View {
            if hasData {
                if let pastDate, !pastDate.isToday {
                    Text("Since no \(healthDetail.name.lowercased()) data has been set for \(pastDate.shortDateString), the most recent entry prior to that is being used.")
                } else {
                    Text("Since no \(healthDetail.name.lowercased()) data has been set for today, the most recent entry is being used.")
                }
            } else if isRequired {
                Text("Your \(healthDetail.name.lowercased()) is required for this calculation.")
            }
        }
        
        var date: Date? {
            switch healthDetail {
            case .height: Date(fromDateString: "2017_01_13")!
            case .weight: (pastDate ?? Date.now).moveDayBy(-1)
//            case .weight: (pastDate ?? Date.now).moveDayBy(0)
            case .leanBodyMass: nil
            default:            nil
            }
        }
        
        var dateIsInPast: Bool {
            guard let date else { return false }
            return if let pastDate {
                date.startOfDay != pastDate.startOfDay
            } else {
                date.startOfDay != Date.now.startOfDay
            }
        }

        var valueString: String? {
            switch healthDetail {
            case .height: "177 cm"
            case .weight: "95.7 kg"
            case .leanBodyMass: nil
            default:            nil
            }
        }
        
        @ViewBuilder
        var measurementLink: some View {
            switch healthDetail {
            case .weight:
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
            case .height:
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
            default:
                EmptyView()
            }
        }
        
        @ViewBuilder
        var setMeasurementLink: some View {
            if date == nil || dateIsInPast {
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
                        Text("Not Set")
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(isEditing && isPast)
            }
        }
        
        return Section(header: header, footer: footer) {
            measurementLink
            setMeasurementLink
        }
    }
    
    var characteristics: [HealthDetail] {
        healthDetails.characteristics
    }
    
    var measurements: [HealthDetail] {
        healthDetails.measurements
    }
    
    var isPast: Bool {
        pastDate != nil
    }
}
