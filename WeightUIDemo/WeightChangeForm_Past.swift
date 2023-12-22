import SwiftUI
import SwiftSugar

struct WeightChangeForm_Past: View {
    
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

    @State var includeTrailingPeriod: Bool = false
    @State var includeTrailingZero: Bool = false
    @State var numberOfTrailingZeros: Int = 0

    @State var isEditing = false

    var body: some View {
        NavigationStack {
            Group {
                if hasAppeared {
                    Form {
                        explanation
                        if !isEditing {
                            notice
                        }
                        if isCustom {
                            enterSection
                        } else {
                            weightSections
                        }
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
            TextField("kg", text: customValueTextBinding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCustomValue)
            Button("Cancel") { }
        }
    }
    
    var notice: some View {
        NoticeSection(
            style: .plain,
            title: "Previous Data",
            message: "This data has been preserved to ensure any goals set on this day remain unchanged.",
            image: {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 30))
                    .padding(5)
            }
        )
    }
    
    var weightSections: some View {
        Group {
            Section {
                NavigationLink {
                    WeightChangePointForm_Past()
                } label: {
                    HStack {
                        Text("22 Dec")
                        Spacer()
                        Text("93.4 kg")
                    }
                }
                .disabled(isEditing)
            }
            Section {
                NavigationLink {
                    WeightChangePointForm_Past()
                } label: {
                    HStack {
                        Text("15 Dec")
                        Spacer()
                        Text("94.2 kg")
                    }
                }
                .disabled(isEditing)
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
        var section: some View {
            Section("15 – 22 Dec") {
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
        
        return Group {
            if isEditing {
                section
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
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        withAnimation {
                            isEditing = false
                        }
                    } else {
                        withAnimation {
                            isEditing = true
                        }
                    }
                }
                .fontWeight(.semibold)
            }
            ToolbarItem(placement: .topBarLeading) {
                if isEditing {
                    Button("Cancel") {
                        withAnimation {
                            isEditing = false
                        }
                    }
                }
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
                Text("Calculate").tag(false)
                Text("Custom").tag(true)
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
            .disabled(!isEditing)
        }
    }
}

#Preview {
    WeightChangeForm_Past()
}
