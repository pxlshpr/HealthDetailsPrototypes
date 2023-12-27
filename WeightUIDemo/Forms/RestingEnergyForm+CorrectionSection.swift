import SwiftUI

extension RestingEnergyForm {
    
    var correctionSection: some View {
        
        var footer: some View {
            var string: String {
                if applyCorrection, let correction {
                    switch correctionType {
                    case .divide:
                        "Your Resting Energy from Apple Health is being divided by \(correction.clean) before being used."
                    case .multiply:
                        "Your Resting Energy from Apple Health is being multiplied by \(correction.clean) before being used."
                    case .add:
                        "\(correction.clean) kcal is being added to your Resting Energy from Apple Health before being used."
                    case .subtract:
                        "\(correction.clean) kcal is being subtracted from your Resting Energy from Apple Health before being used."
                    }
                } else {
                    "If you have reason to believe that the data from Apple Health may be inaccurate, use a correction to account for this."
                }
            }
            
            return Text(string)
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
    }
}
