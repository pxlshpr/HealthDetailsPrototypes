import SwiftUI
import SwiftSugar

struct WeightChangeForm: View {
    
    @Environment(\.dismiss) var dismiss

    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24

    @State var isCustom: Bool = true
    @State var value: Double? = nil

    @State var isSynced: Bool = true
    @State var showingSyncOffConfirmation: Bool = false

    @State var showingAlert = false
    @State var isGain = true
    @State var customValue: Double? = nil
    @State var customValueTextAsDouble: Double? = nil
    @State var customValueText: String = ""

    @State var includeTrailingPeriod: Bool = false
    @State var includeTrailingZero: Bool = false
    @State var numberOfTrailingZeros: Int = 0


    var body: some View {
        Form {
            explanation
            if isCustom {
                enterSection
            } else {
                weightSections
            }
        }
        .navigationTitle("Weight Change")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .alert("Enter your weight \(isGain ? "gain" : "loss")", isPresented: $showingAlert) {
            TextField("kg", text: customValueTextBinding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCustomValue)
            Button("Cancel") { }
        }
    }
    
    enum PreviousPointRoute {
        case form
    }

    enum CurrentPointRoute {
        case form
    }

    var weightSections: some View {
        Group {
            Section {
                NavigationLink(value: PreviousPointRoute.form) {
                    HStack {
                        Text("22 Dec")
                        Spacer()
                        Text("93.4 kg")
                    }
                }
                .navigationDestination(for: PreviousPointRoute.self) { _ in
                    WeightChangePointForm()
                }
            }
            Section {
                NavigationLink(value: CurrentPointRoute.form) {
                    HStack {
                        Text("15 Dec")
                        Spacer()
                        Text("94.2 kg")
                    }
                }
                .navigationDestination(for: PreviousPointRoute.self) { _ in
                    WeightChangePointForm()
                }
            }
        }
    }
    var customValueTextBinding: Binding<String> {
        Binding<String>(
            get: { customValueText },
            set: { newValue in
                /// Cleanup by removing any extra periods and non-numbers
                let newValue = newValue.sanitizedDouble
                customValueText = newValue
                
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
                customValueTextAsDouble = double
                
//                customValueText = if let customValueTextAsDouble {
//                    "\(customValueTextAsDouble)"
//                } else {
//                    ""
//                }
            }
        )
    }
    
    func submitCustomValue() {
        withAnimation {
            customValue = customValueTextAsDouble
            if let customValue {
                value = isGain ? customValue : -customValue
            }
        }
    }
    
    var enterSection: some View {
        let binding = Binding<Bool>(
            get: { isGain },
            set: { newValue in
                withAnimation {
                    isGain = newValue
                    if let value {
                        switch isGain {
                        case true:  self.value = abs(value)
                        case false: self.value = abs(value) * -1
                        }
                    }
                }
            }
        )
        return Section("15 – 22 Dec") {
            Picker("", selection: binding) {
                Text("Gain").tag(true)
                Text("Loss").tag(false)
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
            Button {
                showingAlert = true
            } label: {
                Text("\(customValue == nil ? "Set" : "Change") Weight \(isGain ? "Gain" : "Loss")")
            }
        }
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Spacer()
                    if let value {
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text("\(value.clean)")
                                .contentTransition(.numericText(value: value))
                                .font(LargeNumberFont)
                            Text("kg")
                                .font(LargeUnitFont)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Not Set")
                            .foregroundStyle(.secondary)
                            .font(LargeUnitFont)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }

    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Your weight change can be set by either:")
                dotPoint("Using current and previous weights to calculate it.")
                dotPoint("Entering it in manually.")
            }
            Picker("", selection: Binding<Bool>(
                get: { isCustom },
                set: { newValue in
                    withAnimation {
                        isCustom = newValue
                        customValue = 0.8
                        value = -0.8
                        isGain = false
                    }
                }
            )) {
//                Text("Calculate").tag(false)
                Text("Use Weights").tag(false)
                Text("Enter Manually").tag(true)
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
        }
    }
}

#Preview {
    WeightChangeForm()
}
