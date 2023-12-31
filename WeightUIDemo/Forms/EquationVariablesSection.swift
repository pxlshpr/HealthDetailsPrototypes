import SwiftUI

struct EquationVariablesSections: View {

    @Bindable var provider: HealthProvider
    
    @Binding var healthDetails: [HealthDetail]
    let pastDate: Date?
    @Binding var isEditing: Bool
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool
    let showHeader: Bool
    
    init(
        healthDetails: Binding<[HealthDetail]>,
        provider: HealthProvider,
        pastDate: Date?,
        isEditing: Binding<Bool>,
        isPresented: Binding<Bool>,
        dismissDisabled: Binding<Bool>,
        showHeader: Bool = true
    ) {
        self.provider = provider
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
            case .age:  AgeForm(provider: provider)
            case .sex:  SexForm(provider: provider)
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
        
        @ViewBuilder
        var footer: some View {
            if dateIsInPast {
                if let pastDate {
                    Text("Since no \(healthDetail.name.lowercased()) data has been set for \(pastDate.shortDateString), the most recent entry prior to that is being used.")
                } else {
                    Text("Since no \(healthDetail.name.lowercased()) data has been set for today, the most recent entry is being used.")
                }
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
            if let date, let valueString {
                NavigationLink {
                    switch healthDetail {
                    case .height:
                        HeightForm(
                            pastDate: pastDate,
                            isPresented: $isPresented
                        )
                    case .weight:
                        WeightForm()
                    case .leanBodyMass:
                        LeanBodyMassForm(
                            provider: provider,
                            isPresented: $isPresented,
                            dismissDisabled: $dismissDisabled
                        )
                    default:
                        EmptyView()
                    }
                } label: {
                    HStack {
                        Text(date.shortDateString)
                        Spacer()
                        Text(valueString)
                    }
                }
                .disabled(isEditing && isPast)
            }
        }
        
        @ViewBuilder
        var setMeasurementLink: some View {
            if date == nil || dateIsInPast {
                NavigationLink {
                    switch healthDetail {
                    case .height:
                        HeightForm(
                            pastDate: pastDate,
                            isPresented: $isPresented
                        )
                    case .weight:
                        WeightForm()
                    case .leanBodyMass:
                        LeanBodyMassForm(
                            provider: provider,
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
