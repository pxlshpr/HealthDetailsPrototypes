import SwiftUI
import SwiftSugar

struct WeightChangeForm: View {
    
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

    let pastDate: Date?
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool

    init(pastDate: Date? = nil, isPresented: Binding<Bool> = .constant(true)) {
        self.pastDate = pastDate
        _isPresented = isPresented
        _isEditing = State(initialValue: pastDate == nil)
    }

    var body: some View {
        Form {
            notice
            typePicker
            if isCustom {
                enterSection
            } else {
                weightSections
            }
            explanation
        }
        .navigationTitle("Weight Change")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .navigationBarBackButtonHidden(isEditing && isPast)
        .alert("Enter your weight \(isGain ? "gain" : "loss")", isPresented: $showingAlert) {
            TextField("kg", text: customValueTextBinding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCustomValue)
            Button("Cancel") { }
        }
    }
    
    var isPast: Bool {
        pastDate != nil
    }
    
    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: $isEditing)
        }
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            bottomToolbarContent(
                value: value,
                valueString: value?.formattedEnergy,
                isDisabled: !isEditing,
                unitString: "kcal"
            )
            topToolbarContent(
                isEditing: $isEditing,
                isDirty: $isDirty,
                isPast: isPast,
                dismissAction: { isPresented = false },
                undoAction: undo,
                saveAction: save
            )
        }
    }
    
    func save() {
        
    }
    
    func undo() {
        isDirty = false
        isCustom = true
        value = nil
        customValue = nil
        customValueTextAsDouble = nil
        customValueText = ""
    }
    
    func setIsDirty() {
        isDirty = self.isGain != true
        || self.customValue != nil
        || self.value != nil
        || self.isCustom != true
    }
    
    var weightSections: some View {
        Group {
            Section {
                NavigationLink {
                    WeightChangePointForm(
                        pastDate: pastDate,
                        isPresented: $isPresented,
                        dateString: "24 Dec",
                        isCurrent: true
                    )
                } label: {
                    HStack {
                        Text("24 Dec")
                        Spacer()
                        Text("93.4 kg")
                    }
                }
                .disabled(isEditing && isPast)
            }
            Section {
                NavigationLink {
                    WeightChangePointForm(
                        pastDate: pastDate,
                        isPresented: $isPresented,
                        dateString: "17 Dec",
                        isCurrent: false
                    )
                } label: {
                    HStack {
                        Text("17 Dec")
                        Spacer()
                        Text("94.2 kg")
                    }
                }
                .disabled(isEditing && isPast)
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
            setIsDirty()
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
                    setIsDirty()
                }
            }
        )
        var section: some View {
            Section("Weight Change") {
                Picker("", selection: binding) {
                    Text("Weight Gain").tag(true)
                    Text("Weight Loss").tag(false)
                }
                .pickerStyle(.segmented)
                Button {
                    showingAlert = true
                } label: {
                    Text("\(customValue == nil ? "Set" : "Edit") Weight \(isGain ? "Gain" : "Loss")")
                }
            }
        }
        
        return Group {
            if isEditing {
                section
            }
        }
    }
    
//    var toolbarContent: some ToolbarContent {
//        Group {
//            ToolbarItem(placement: .bottomBar) {
//                HStack {
//                    Spacer()
//                    if let value {
//                        HStack(alignment: .firstTextBaseline, spacing: 5) {
//                            Text("\(value.clean)")
//                                .contentTransition(.numericText(value: value))
//                                .font(LargeNumberFont)
//                            Text("kg")
//                                .font(LargeUnitFont)
//                                .foregroundStyle(.secondary)
//                        }
//                    } else {
//                        Text("Not Set")
//                            .foregroundStyle(.secondary)
//                            .font(LargeUnitFont)
//                    }
//                }
//            }
//            ToolbarItem(placement: .topBarTrailing) {
//                Button("Done") {
//                    dismiss()
//                }
//                .fontWeight(.semibold)
//            }
//        }
//    }
    
    var explanation: some View {
        Section {
            Text("This represents the change in your weight from 17-24 December, which is used to calculate your Adaptive Maintenance Energy.")
        }
    }

    var typePicker: some View {
        Section {
            Picker("", selection: Binding<Bool>(
                get: { isCustom },
                set: { newValue in
                    withAnimation {
                        isCustom = newValue
                        customValue = 0.8
                        value = -0.8
                        isGain = false
                        setIsDirty()
                    }
                }
            )) {
//                Text("Calculate").tag(false)
                Text("Use Weights").tag(false)
                Text("Enter Manually").tag(true)
            }
            .pickerStyle(.segmented)
            .disabled(!isEditing)
//            .listRowSeparator(.hidden)
            .listRowBackground(EmptyView())
        }
    }
}

#Preview("Current") {
    NavigationView {
        WeightChangeForm()
    }
}

#Preview("Past") {
    NavigationView {
        WeightChangeForm(pastDate: MockPastDate)
    }
}
