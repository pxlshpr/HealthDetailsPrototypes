import SwiftUI

struct DietaryEnergyPointForm: View {
    
    @Environment(\.dismiss) var dismiss
    
    let dateString: String
    
    @State var type: DietaryEnergyPointType = .log
    @State var value: Double? = 2356

    @State var showingAlert = false
    @State var customValue: Double? = nil
    @State var customValueTextAsDouble: Double? = nil
    @State var customValueText: String = ""

    @State var includeTrailingPeriod: Bool = false
    @State var includeTrailingZero: Bool = false
    @State var numberOfTrailingZeros: Int = 0

    let pastDate: Date?
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    
    @State var showingInfo = false
    
    init(dateString: String, pastDate: Date? = nil) {
        self.pastDate = pastDate
        _isEditing = State(initialValue: pastDate == nil)
        self.dateString = dateString
    }

    var body: some View {
        NavigationView {
            Form {
                notice
                picker
                if type == .custom {
                    customSection
                }
                explanation
            }
            .navigationTitle(dateString)
            .toolbar { toolbarContent }
            .alert("Enter your dietary energy", isPresented: $showingAlert) {
                TextField("kcal", text: customValueTextBinding)
                    .keyboardType(.decimalPad)
                Button("OK", action: submitCustomValue)
                Button("Cancel") { }
            }
        }
        .sheet(isPresented: $showingInfo) {
            AdaptiveDietaryEnergyInfo()
        }
    }
    
    var isPast: Bool {
        pastDate != nil
    }
    
    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(
                pastDate,
                isEditing: $isEditing
            )
        }
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .bottomBar) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Spacer()
                    if let value {
                        Text("\(value.formattedEnergy)")
                            .contentTransition(.numericText(value: value))
                            .font(LargeNumberFont)
                        Text("kcal")
                            .font(LargeUnitFont)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(type == .custom ? "Not Set" : "Not Included")
                            .font(LargeUnitFont)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            topToolbarContent(
                isEditing: $isEditing,
                isDirty: $isDirty,
                isPast: isPast,
                dismissAction: { dismiss() },
                undoAction: undo,
                saveAction: save
            )
        }
    }
    
    func save() {
        
    }
    
    func undo() {
        isDirty = false
        value = 2893
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
            value = customValue
        }
    }
    
    var customSection: some View {
        Section {
            Button {
                showingAlert = true
            } label: {
                Text("\(value != nil ? "Edit" : "Set") Dietary Energy")
            }
            .disabled(!isEditing)
        }
    }
    
    func value(for type: DietaryEnergyPointType) -> Double? {
        switch type {
        case .log:          2356
        case .healthKit:    2223
        case .fasted:       0
        case .custom:       nil
        case .notIncluded:  nil
        }
    }
    
    var picker: some View {
        let binding = Binding<DietaryEnergyPointType>(
            get: { type },
            set: { newValue in
                withAnimation {
                    type = newValue
                    self.value = value(for: newValue)
                }
                if newValue == .custom {
                    showingAlert = true
                }
                isDirty = type != .log
            }
        )
        return Section {
            Picker("Dietary Energy", selection: binding) {
                ForEach(DietaryEnergyPointType.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.menu)
            .foregroundStyle(isEditing ? .primary : .secondary)
            .disabled(!isEditing)
        }
    }
    
    var isDisabled: Bool {
        isPast && !isEditing
    }
    
    var explanation: some View {
        @ViewBuilder
        var footer: some View {
            if !isDisabled {
                Button {
                    showingInfo = true
                } label: {
                    Text("Learn more…")
                        .font(.footnote)
                }
            }
        }

        return Section(footer: footer) {
                Text("This is the dietary energy being used for this date when calculating your adaptive maintenance energy. You can set it in multiple ways.")
        }
    }
}

#Preview("Current") {
    DietaryEnergyPointForm(dateString: "22 Dec")
}

#Preview("Past") {
    DietaryEnergyPointForm(dateString: "22 Dec", pastDate: MockPastDate)
}
