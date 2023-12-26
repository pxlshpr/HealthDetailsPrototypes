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
        NavigationStack {
            Form {
                notice
                picker
                if type == .custom {
                    customSection
                }
                explanation
            }
            .padding(.top, 0.3) /// Navigation Bar Fix
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

struct AdaptiveDietaryEnergyInfo: View {
    
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            form
                .navigationTitle("Setting Dietary Energy")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    var form: some View {
        Form {
            InfoSection("Log", "This will use the energy total from your food log.\n\nChoose this if you logged all the food you consumed reliably on this date.")
            InfoSection("Apple Health", "This will fetch the data recorded in the Apple Health for this date.\n\nChoose this if you have the correct data in there, either entered manually or exported from another app.")
            InfoSection("Fasted", "This will mark this day as fasted by assigning it a dietary energy of zero.\n\nMake sure you choose this for the days where you consumed no calories, as they would be assigned the average of the other days otherwise.")
            InfoSection("Custom", "Choosing this will allow you to enter the dietary manually.")
            InfoSection("Not Included", "This will not include this day's dietary energy and instead assigns it the average of the other days.\n\nChoose this if you don't believe you have a complete and accurate log of the food you ate for this date.")
        }
    }
    
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Done") {
                dismiss()
            }
            .fontWeight(.semibold)
        }
    }

}

#Preview("Current") {
    DietaryEnergyPointForm(dateString: "22 Dec")
}

#Preview("Past") {
    DietaryEnergyPointForm(dateString: "22 Dec", pastDate: MockPastDate)
}
