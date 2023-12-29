import SwiftUI

struct DietaryEnergyPointForm: View {
    
    let dateString: String
    
    @State var type: DietaryEnergyPointType = .log
    @State var value: Double? = 2356

    @State var showingAlert = false
    
    @State var customInput = DoubleInput()

    @State var showingInfo = false
    
    let pastDate: Date?
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool

    init(dateString: String, pastDate: Date? = nil, isPresented: Binding<Bool> = .constant(true)) {
        self.pastDate = pastDate
        _isEditing = State(initialValue: pastDate == nil)
        self.dateString = dateString
        _isPresented = isPresented
    }

    var body: some View {
//        NavigationView {
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
            .navigationBarBackButtonHidden(isEditing && isPast)
            .alert("Enter your dietary energy", isPresented: $showingAlert) {
                TextField("kcal", text: customInput.binding)
                    .keyboardType(.decimalPad)
                Button("OK", action: submitCustomValue)
                Button("Cancel") { customInput.cancel() }
            }
//        }
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
        value = 2893
    }
    
    func submitCustomValue() {
        withAnimation {
            customInput.submitValue()
            value = customInput.double
            setIsDirty()
        }
    }
    
    func setIsDirty() {
        isDirty = type != .log
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
        case .useAverage:  nil
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
                setIsDirty()
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
                Text("This is the dietary energy being used for this date when calculating your Adaptive Maintenance Energy. You can set it in multiple ways.")
        }
    }
}

#Preview("Current") {
    NavigationView {
        DietaryEnergyPointForm(dateString: "22 Dec")
    }
}

#Preview("Past") {
    NavigationView {
        DietaryEnergyPointForm(dateString: "22 Dec", pastDate: MockPastDate)
    }
}
