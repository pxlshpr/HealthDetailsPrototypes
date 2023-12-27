import SwiftUI

extension RestingEnergyForm {

    var variablesSections: some View {
        let healthDetails = equation.requiredHealthDetails
        let characteristics = healthDetails.characteristics
        let measurements = healthDetails.measurements

        var mainHeader: some View {
            Text("Equation Variables")
                .textCase(.none)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(Color(.label))
        }
        
        func link(for characteristic: HealthDetail) -> some View {
            NavigationLink {
                switch characteristic {
                case .age:  AgeForm()
                case .sex:  SexForm()
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
                    Text("Since no \(healthDetail.name.lowercased()) data has been set for \(formDate.dateString), the most recent entry prior to that is being used.")
                }
            }
            
            var date: Date? {
                switch healthDetail {
                case .height: Date(fromDateString: "2017_01_13")!
                case .weight: pastDate ?? Date.now
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
                            HeightForm(mode: .restingEnergyVariable(nil))
                        case .weight:
                            WeightForm()
                        case .leanBodyMass:
                            LeanBodyMassForm()
                        default:
                            EmptyView()
                        }
                    } label: {
                        HStack {
                            Text(date.dateString)
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
                        
                    } label: {
                        HStack {
                            Text(formDate.dateString)
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
        
        return Group {
            characteristicsSection
            measurementSections
        }
    }
    
}
