import SwiftUI

struct DietaryEnergyPointForm_Past: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State var type: DietaryEnergyPointType = .custom
    @State var value: Double? = 2356

    @State var showingAlert = false
    @State var customValue: Double? = nil
    @State var customValueTextAsDouble: Double? = nil
    @State var customValueText: String = ""

    @State var includeTrailingPeriod: Bool = false
    @State var includeTrailingZero: Bool = false
    @State var numberOfTrailingZeros: Int = 0

    @State var isEditing = false

    var body: some View {
        NavigationStack {
            Form {
                if !isEditing {
                    notice
                } else {
                    explanation
                }
                picker
                if type == .custom {
                    customSection
                }
            }
            .navigationTitle("22 Dec")
            .toolbar { toolbarContent }
            .alert("Enter your dietary energy", isPresented: $showingAlert) {
                TextField("kcal", text: customValueTextBinding)
                    .keyboardType(.decimalPad)
                Button("OK", action: submitCustomValue)
                Button("Cancel") { }
            }
        }
    }
    
    var notice: some View {
        NoticeSection(
            style: .plain,
            title: "Previous Data",
            message: "This data has been preserved to ensure any goals set on this day remain unchanged."
//            image: {
//                Image(systemName: "calendar.badge.clock")
//                    .font(.system(size: 30))
//                    .padding(5)
//            }
        )
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
                Text("\(value != nil ? "Edit" : "Set")")
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
    
    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("The daily dietary energy to use for this date. You can specify it in a few ways:")
                dotPoint("\"Log\" uses the value from your food log. Choose this if you logged all the food you consumed reliably.")
                dotPoint("\"Apple Health\" uses the data recorded in the Health App.")
                dotPoint("\"Fasted\" marks the day as fasted, and assigns it a dietary energy of zero.")
                dotPoint("\"Custom\" allows you to enter the energy manually.")
                dotPoint("\"Not Included\" does not include this day's dietary energy and assigns it the average. Choose this if you don't have a complete or accurate log of the food you ate.")
            }
        }
    }
}

#Preview {
    DietaryEnergyPointForm_Past()
}
