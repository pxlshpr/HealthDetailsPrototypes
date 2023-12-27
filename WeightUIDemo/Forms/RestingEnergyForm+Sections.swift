import SwiftUI

extension RestingEnergyForm {

    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: $isEditing)
        }
    }
    
    var sourceSection: some View {
        let binding = Binding<RestingEnergySource>(
            get: { source },
            set: { newValue in
                withAnimation {
                    source = newValue
                    setIsDirty()
                }
                if source == .userEntered {
                    showingAlert = true
                }
            }
        )
        
        return Section {
            Picker("Resting Energy", selection: binding) {
                ForEach(RestingEnergySource.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .foregroundStyle(controlColor)
            .pickerStyle(.menu)
        }
        .disabled(isDisabled)
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
        
        @ViewBuilder
        var footer: some View {
            if !isDisabled {
                Button {
                    showingHealthIntervalInfo = true
                } label: {
                    Text("Learn more…")
                        .font(.footnote)
                }
            }
        }

        return Section(footer: footer) {
            Picker("Use", selection: binding) {
                ForEach(HealthIntervalType.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.menu)
            .disabled(isDisabled)
            .foregroundStyle(controlColor)
        }
    }
    
    var intervalSection: some View {
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
            title: "Average of Previous",
            isDisabled: Binding<Bool>(
                get: { isDisabled },
                set: { _ in }
            )
        )
    }
    
    var explanation: some View {
        var header: some View {
            Text("About Resting Energy")
                .textCase(.none)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(Color(.label))
        }
        return Section(header: header) {
            VStack(alignment: .leading) {
                Text("Your Resting Energy, or your Basal Metabolic Rate (BMR), is the energy your body uses each day while minimally active. You can set it in three ways:")
                dotPoint("\"Apple Health\" uses the data recorded in the Health App.")
                dotPoint("\"Equation\" calculates it using your health details.")
                dotPoint("\"Custom\" allows you to enter the energy manually.")
            }
        }
    }

    @ViewBuilder
    var customSection: some View {
        if !isDisabled {
            Section {
                Button {
                    showingAlert = true
                } label: {
                    Text("\(value != nil ? "Edit" : "Set") Resting Energy")
                }
            }
        }
    }
    
    var equationSection: some View {
        let binding = Binding<RestingEnergyEquation>(
            get: { equation },
            set: { newValue in
                withAnimation {
                    equation = newValue
                    setIsDirty()
                }
            }
        )
        
        @ViewBuilder
        var footer: some View {
            if !isDisabled {
                Button {
                    showingEquationsInfo = true
                } label: {
                    Text("Learn more…")
                        .font(.footnote)
                }
            }
        }
        
        return Section(footer: footer) {
            Picker("Equation", selection: binding) {
                ForEach(RestingEnergyEquation.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.menu)
            .disabled(isDisabled)
            .foregroundStyle(controlColor)
        }
    }
    
}
