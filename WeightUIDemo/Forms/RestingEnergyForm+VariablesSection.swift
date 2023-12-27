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
            .disabled(isEditing)
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
            
            @ViewBuilder
            var footer: some View {
                if dateIsInPast, valueString != nil {
                    Text("Your latest available height data is being used.")
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
                if let pastDate {
                    date?.startOfDay != pastDate.startOfDay
                } else {
                    date?.startOfDay != Date.now.startOfDay
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
                    .disabled(isEditing)
                }
            }
            
            var setMeasurementLink: some View {
                
                var dateString: String {
                    if let pastDate {
                        " on \(pastDate.dateString)"
                    } else {
                        " for Today"
                    }
                }
                
                var label: String {
                    "Set \(healthDetail.name)\(date == nil ? "" : dateString)"
                }
                
                return Group {
                    if dateIsInPast, isEditing {
                        NavigationLink {
                            
                        } label: {
                            Text(label)
                                .foregroundStyle(Color.accentColor)
                        }
                    }
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
