import SwiftUI
import SwiftSugar

struct WeightChangeForm: View {
    
    @Environment(\.dismiss) var dismiss

    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24

    @State var hasAppeared = false
    @State var isCustom: Bool = true
    @State var value: Double? = nil

    @State var isSynced: Bool = true
    @State var showingSyncOffConfirmation: Bool = false

    @State var showingAlert = false
    @State var isGain = true
    @State var customValue: Double? = nil
    @State var customValueTextAsDouble: Double? = nil
    @State var customValueText: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if hasAppeared {
                    Form {
                        explanation
//                        typePicker
                        if isCustom {
                            enterSection
                        }
//                        syncToggle
                    }
                } else {
                    Color.clear
                }
            }
            .navigationTitle("Weight Change")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                hasAppeared = true
            }
        }
        .alert("Enter your weight \(isGain ? "gain" : "loss")", isPresented: $showingAlert) {
            Picker("", selection: $isCustom) {
                Text("Calculate").tag(false)
                Text("Custom").tag(true)
            }
            .pickerStyle(.segmented)
            TextField("kg", text: customValueTextBinding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCustomValue)
            Button("Cancel") { }
        }
    }
    
    @State var includeTrailingPeriod: Bool = false
    @State var includeTrailingZero: Bool = false
    @State var numberOfTrailingZeros: Int = 0

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
    
    var typePicker: some View {
        Section {
            Picker("", selection: $isCustom) {
                Text("Calculate").tag(false)
                Text("Custom").tag(true)
            }
            .pickerStyle(.segmented)
        }
    }

    var syncToggle: some View {
        let binding = Binding<Bool>(
            get: { isSynced },
            set: {
                if !$0 {
                    showingSyncOffConfirmation = true
                }
            }
        )

        return Section(footer: Text("Automatically reads weight data from Apple Health. Data you enter here will also be exported back to Apple Health.")) {
            HStack {
                Image("AppleHealthIcon")
                    .resizable()
                    .frame(width: imageScale * scale, height: imageScale * scale)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(.systemGray3), lineWidth: 0.5)
                    )
                Text("Sync with Apple Health")
                    .layoutPriority(1)
                Spacer()
                Toggle("", isOn: binding)
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
                            .font(LargeNumberFont)
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
                Text("This is your weight change used in the adaptive maintenance energy calculation. You can either:")
                Label {
                    Text("Calculate it using current and previous weights.")
                } icon: {
                    Circle()
                        .foregroundStyle(Color(.label))
                        .frame(width: 5, height: 5)
                }
                Label {
                    Text("Enter the weight change directly.")
                } icon: {
                    Circle()
                        .foregroundStyle(Color(.label))
                        .frame(width: 5, height: 5)
                }
            }
            Picker("", selection: $isCustom) {
                Text("Calculate").tag(false)
                Text("Custom").tag(true)
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
        }
    }
}

#Preview {
    WeightChangeForm()
}

public extension String {
    var sanitizedDouble: String {
        var chars: [Character] = []
        var hasPeriod: Bool = false
        forLoop: for (index, char) in self.enumerated() {
            
            switch char {
            case ".":
                /// Only allow period once, otherwise ignoring it and rest of string
                if hasPeriod {
                    break forLoop
                } else {
                    hasPeriod = true
                    chars.append(char)
                }
                
            case "-":
                /// Only allow negative sign if first character, otherwise ignoring it and rest of string
                guard index == 0 else {
                    break forLoop
                }
                chars.append(char)
                
            default:
                /// Only allow numbers
                guard char.isNumber else {
                    break forLoop
                }
                chars.append(char)
            }
        }
        return String(chars)
    }
}
