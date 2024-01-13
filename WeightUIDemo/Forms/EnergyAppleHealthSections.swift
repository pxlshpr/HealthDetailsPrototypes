import SwiftUI

struct EnergyAppleHealthSections: View {
    
    let date: Date
    @Binding var intervalType: HealthIntervalType
    @Binding var interval: HealthInterval

    @Binding var applyCorrection: Bool
    @Binding var correctionType: CorrectionType
    @Binding var correctionInput: DoubleInput

    let handleChanges: () -> ()
    let isRestingEnergy: Bool

    @State var showingHealthIntervalInfo = false
    @State var showingCorrectionInfo = false
    @Binding var energyInKcal: Double?
    
    let energyUnitString: String
    
    @State var hasFocusedCorrectionField = true
    
    var body: some View {
        Group {
            intervalTypeSection
            missingDataSection
            correctionSection
        }
    }
    
    var intervalTypeSection: some View {
        let binding = Binding<HealthIntervalType>(
            get: { intervalType },
            set: { newValue in
                withAnimation {
                    intervalType = newValue
                    handleChanges()
                }
            }
        )
        
        var footer: some View {
            
            func handleURL(_ url: URL) {
                showingHealthIntervalInfo = true
            }
            
            var description: String {
                intervalType.footerDescription(date, interval: interval, isResting: isRestingEnergy)
            }
            
            return VStack(alignment: .leading) {
                Text("\(description) [Learn more…](https://dummyurl.com)")
                    .environment(\.openURL, OpenURLAction { url in
                        handleURL(url)
                        return .handled
                    })
            }
        }
        
        var header: some View {
            Text("Apple Health Data")
                .formTitleStyle()
        }
        
        var pickerRow: some View {
            Picker("Use", selection: binding) {
                ForEach(HealthIntervalType.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.wheel)
        }
        
        @ViewBuilder
        var intervalRow: some View {
            if intervalType == .average {
                intervalPicker
            }
        }

        return Section(header: header, footer: footer) {
            pickerRow
            intervalRow
        }
        .sheet(isPresented: $showingHealthIntervalInfo) {
            HealthIntervalInfo(isRestingEnergy: isRestingEnergy)
        }
    }
    
    var intervalPicker: some View {
        var binding: Binding<HealthInterval> {
            Binding<HealthInterval>(
                get: { interval },
                set: { newValue in
                    withAnimation {
                        interval = newValue
                    }
                    handleChanges()
                }
            )
        }

        return IntervalPicker(
            interval: binding,
            periods: [.day, .week],
            ranges: [
                .day: 2...6,
                .week: 1...2
            ],
            title: "of previous"
        )
    }
    var name: String {
        isRestingEnergy ? "Resting Energy" : "Active Energy"
    }
}

extension EnergyAppleHealthSections {
    
    var correction: Double? {
        correctionInput.double
    }
    
    var correctionSection: some View {
        
        var footer: some View {
            var string: String {
                if applyCorrection, let correction {
                    switch correctionType {
                    case .divide:
                        "Your \(name) from Apple Health is being divided by \(correction.clean) before being used."
                    case .multiply:
                        "Your \(name) from Apple Health is being multiplied by \(correction.clean) before being used."
                    case .add:
                        "\(correction.clean) \(energyUnitString) is being added to your \(name) from Apple Health before being used."
                    case .subtract:
                        "\(correction.clean) \(energyUnitString) is being subtracted from your \(name) from Apple Health before being used."
                    }
                } else {
                    "If you have reason to believe that the data from Apple Health may be inaccurate, use a correction to account for this."
                }
            }
            
            return Text("\(string) [Learn More](https://dummyurl.com)")
                .environment(\.openURL, OpenURLAction { url in
                    handleURL(url)
                    return .handled
                })
        }
        
        func handleURL(_ url: URL) {
            showingCorrectionInfo = true
        }
        
        var toggleRow: some View {
            let binding = Binding<Bool>(
                get: { applyCorrection },
                set: { newValue in
                    if newValue {
                        hasFocusedCorrectionField = false
                    }
                    withAnimation {
                        applyCorrection = newValue
                    }
                    handleChanges()
                }
            )
            return HStack {
                Text("Apply Correction")
                Spacer()
                Toggle("", isOn: binding)
            }
        }
        
        var correctionTypeRow: some View {
            let binding = Binding<CorrectionType>(
                get: { correctionType },
                set: { newValue in
                    withAnimation {
                        correctionType = newValue
                    }
                    handleChanges()
                }
            )
            return Section {
                Picker("Type", selection: binding) {
                    ForEach(CorrectionType.allCases, id: \.self) {
                        Text($0.name).tag($0)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        
        var correctionRow: some View {
            func handleCustomValue() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    handleChanges()
                }
            }
            
            func validateCorrection() {
                guard let double = correctionInput.double,
                      double > 0
                else {
                    correctionInput.setDouble(nil)
                    applyCorrection = false
                    handleChanges()
                    return
                }
            }
            
            func handleLostFocus() {
                validateCorrection()
            }
            
            var title: String {
                switch correctionType {
                case .add, .subtract:
                    energyUnitString
                case .divide:
                    "Divide by"
                case .multiply:
                    "Multiply by"
                }
            }
            
            return SingleUnitMeasurementTextField(
                title: title,
                doubleInput: $correctionInput,
                hasFocused: $hasFocusedCorrectionField,
                delayFocus: true,
                footer: nil,
                handleChanges: handleCustomValue,
                handleLostFocus: handleLostFocus
            )
        }
        
        var section: some View {
            Section(header: Text("Correction"), footer: footer) {
                toggleRow
                if applyCorrection {
                    correctionTypeRow
                    correctionRow
                }
            }
            .sheet(isPresented: $showingCorrectionInfo) {
                AppleHealthCorrectionInfo()
            }
        }
        
        return Group {
            if hasData {
                section
            }
        }
    }
    
    var hasData: Bool {
        guard let energyInKcal else { return false }
        return energyInKcal > 0
    }
    
    @ViewBuilder
    var missingDataSection: some View {
        if !hasData {
            NoticeSection(
                style: .plain,
                notice: .init(
                    title: "Missing Data or Permissions",
                    message: "No data was fetched from Apple Health. This could be because there isn't any data available for \(intervalType.dateDescription(date, interval: interval)) or you have not provided permission to read it.\n\nYou can check for permissions in:\nSettings > Privacy & Security > Health > Prep",
                    imageName: "questionmark.app.dashed"
                )
            )
        }
    }
}
