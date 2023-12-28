import SwiftUI

struct EnergyAppleHealthSections: View {
    
    @Binding var intervalType: HealthIntervalType
    @Binding var interval: HealthInterval
    let pastDate: Date?
    @Binding var isEditing: Bool

    @Binding var applyCorrection: Bool
    @Binding var correctionType: CorrectionType
    @Binding var correction: Double?

    @Binding var correctionTextAsDouble: Double?
    @Binding var correctionText: String

    let setIsDirty: () -> ()
    let isRestingEnergy: Bool
    
    @State var includeTrailingPeriod: Bool = false
    @State var includeTrailingZero: Bool = false
    @State var numberOfTrailingZeros: Int = 0

    @State var showingHealthIntervalInfo = false
    @State var showingCorrectionInfo = false
    @State var showingCorrectionAlert = false

    var body: some View {
        Group {
            intervalTypeSection
            correctionSection
        }
    }
    
    var intervalTypeSection: some View {
        let binding = Binding<HealthIntervalType>(
            get: { intervalType },
            set: { newValue in
                withAnimation {
                    intervalType = newValue
                    setIsDirty()
                }
            }
        )
        
        var footer: some View {
            
            func handleURL(_ url: URL) {
                showingHealthIntervalInfo = true
            }
            
            var description: String {
                intervalType.footerDescription(pastDate, interval: interval)
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
            .pickerStyle(.menu)
            .disabled(isDisabled)
            .foregroundStyle(controlColor)
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
                        setIsDirty()
                    }
                }
            )
        }

        return IntervalPicker(
            interval: binding,
            periods: [.day, .week],
            ranges: [.week: 1...2],
            title: "of previous",
            isDisabled: Binding<Bool>(
                get: { isDisabled },
                set: { _ in }
            )
        )
    }
    
    var isPast: Bool {
        pastDate != nil
    }
    
    var isDisabled: Bool {
        isPast && !isEditing
    }

    var controlColor: Color {
        isDisabled ? .secondary : .primary
    }
    
    var name: String {
        isRestingEnergy ? "Resting Energy" : "Active Energy"
    }
}

extension EnergyAppleHealthSections {
    
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
                        "\(correction.clean) kcal is being added to your \(name) from Apple Health before being used."
                    case .subtract:
                        "\(correction.clean) kcal is being subtracted from your \(name) from Apple Health before being used."
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
                    withAnimation {
                        applyCorrection = newValue
                        setIsDirty()
                    }
                }
            )
            return HStack {
                Text("Apply Correction")
                Spacer()
                Toggle("", isOn: binding)
            }
            .disabled(isDisabled)
            .foregroundStyle(controlColor)
        }
        
        var correctionTypeRow: some View {
            let binding = Binding<CorrectionType>(
                get: { correctionType },
                set: { newValue in
                    withAnimation {
                        correctionType = newValue
//                        value = valueForActivityLevel(newValue)
                        setIsDirty()
                    }
                }
            )
            return Section {
                Picker("Type", selection: binding) {
                    ForEach(CorrectionType.allCases, id: \.self) {
                        Text($0.name).tag($0)
                    }
                }
                .pickerStyle(.menu)
                .disabled(isDisabled)
                .foregroundStyle(controlColor)
            }
        }
        
        var correctionRow: some View {
            HStack {
                if let correction {
                    Group {
                        Text(correctionType.label)
                        Spacer()
                        Text(correction.clean)
                        if let unit = correctionType.unit {
                            Text(unit)
                        }
                    }
                    .foregroundStyle(controlColor)
                    if !isDisabled {
                        Button {
                            showingCorrectionAlert = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                } else {
                    Button("Set Correction") {
                        showingCorrectionAlert = true
                    }
                }
            }
        }
        
        return Section(header: Text("Correction"), footer: footer) {
            toggleRow
            if applyCorrection {
                correctionTypeRow
                if correction != nil || !isDisabled {
                    correctionRow
                }
            }
        }
        .sheet(isPresented: $showingCorrectionInfo) {
            AppleHealthCorrectionInfo()
        }
        .alert("Enter a correction", isPresented: $showingCorrectionAlert) {
            TextField(correctionType.textFieldPlaceholder, text: correctionTextBinding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCorrection)
            Button("Cancel") { }
        }
    }
    
    func submitCorrection() {
        withAnimation {
            correction = correctionTextAsDouble
            setIsDirty()
        }
    }

    var correctionTextBinding: Binding<String> {
        Binding<String>(
            get: { correctionText },
            set: { newValue in
                /// Cleanup by removing any extra periods and non-numbers
                let newValue = newValue.sanitizedDouble
                correctionText = newValue
                
                /// If we haven't already set the flag for the trailing period, and the string has period as its last character, set it so that its displayed
                if !includeTrailingPeriod, newValue.last == "." {
                    includeTrailingPeriod = true
                }
                /// If we have set the flag for the trailing period and the last character isn't it—unset it
                else if includeTrailingPeriod, newValue.last != "." {
                    includeTrailingPeriod = false
                }
                
                if newValue == ".0" {
                    includeTrailingZero = true
                } else {
                    includeTrailingZero = false
                }
                
                let double = Double(newValue)
                correctionTextAsDouble = double

//                customValueText = if let customValueTextAsDouble {
//                    "\(customValueTextAsDouble)"
//                } else {
//                    ""
//                }
            }
        )
    }
}
