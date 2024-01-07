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
    
    @State var customInput = DoubleInput()

    let date: Date
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    init(
        date: Date = Date.now,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.date = date
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: date.isToday)
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
        .alert("Enter your weight \(isGain ? "gain" : "loss")", isPresented: $showingAlert) {
            TextField("kg", text: customInput.binding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCustomValue)
            Button("Cancel") { customInput.cancel() }
        }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isLegacy && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    func setDismissDisabled() {
        dismissDisabled = isLegacy && isEditing && isDirty
    }

    var bottomValue: some View {
        MeasurementBottomBar(
            double: $value,
            doubleString: Binding<String?>(
                get: { valueAsString },
                set: { _ in }
            ),
            doubleUnitString: "kg",
            isDisabled: Binding<Bool>(
                get: { !isEditing },
                set: { _ in }
            )
        )
    }
    
    var isLegacy: Bool {
        date.startOfDay < Date.now.startOfDay
    }
    
    @ViewBuilder
    var notice: some View {
        if isLegacy {
            NoticeSection.legacy(date, isEditing: $isEditing)
        }
    }
    
    var valueAsString: String? {
        guard let value else { return nil }
        return if value > 0 {
            "+\(value.clean)"
        } else {
            value.clean
        }
    }
    
    var toolbarContent: some ToolbarContent {
        topToolbarContent(
            isEditing: $isEditing,
            isDirty: $isDirty,
            isPast: isLegacy,
            dismissAction: { isPresented = false },
            undoAction: undo,
            saveAction: save
        )
    }
    
    func save() {
        
    }
    
    func undo() {
        isDirty = false
        isCustom = true
        value = nil
        customInput = DoubleInput()
    }
    
    func setIsDirty() {
        isDirty = self.isGain != true
        || self.customInput.double != nil
        || self.value != nil
        || self.isCustom != true
    }
    
    var weightSections: some View {
        Group {
            Section("Ending Weight") {
                NavigationLink {
                    WeightChangePointForm(
                        healthDetailsDate: date,
                        weightDate: date,
                        isPresented: $isPresented,
                        dismissDisabled: $dismissDisabled,
                        isCurrent: true
                    )
                } label: {
                    HStack {
                        Text(date.shortDateString)
                        Spacer()
                        Text("93.2 kg")
                    }
                }
                .disabled(isEditing && isLegacy)
            }
            Section("Starting Weight") {
                NavigationLink {
                    WeightChangePointForm(
                        healthDetailsDate: date,
                        weightDate: date.moveDayBy(-7),
                        isPresented: $isPresented,
                        dismissDisabled: $dismissDisabled,
                        isCurrent: false
                    )
                } label: {
                    HStack {
                        Text(date.moveDayBy(-7).shortDateString)
                        Spacer()
                        Text("94.2 kg")
                    }
                }
                .disabled(isEditing && isLegacy)
            }
        }
    }
    
    var customValue: Double? {
        customInput.double
    }
    
    func submitCustomValue() {
        withAnimation {
            customInput.submitValue()
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
        
        var picker: some View {
            Picker("", selection: binding) {
                Text("Weight Gain").tag(true)
                Text("Weight Loss").tag(false)
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
        }
        
        var button: some View {
            var name: String {
                "Weight \(isGain ? "Gain" : "Loss")"
            }
            
            return Button {
                showingAlert = true
            } label: {
//                Text("\(customValue == nil ? "Set" : "Edit") Weight \(isGain ? "Gain" : "Loss")")
                if let customValue {
                    HStack {
                        Text(name)
                            .foregroundStyle(Color(.label))
                        Spacer()
                        Text("\(customValue.clean) kg")
                            .foregroundStyle(Color(.label))
                        Image(systemName: "pencil")
                    }
                } else {
                    Text("Set \(name)")
                }
            }
        }
        var section: some View {
            Section {
                picker
                button
            }
        }
        
        return Group {
            if isEditing {
                section
            }
        }
    }

    var explanation: some View {
        Section {
            Text("This represents the change in your weight from \(date.moveDayBy(-7).shortDateString) to \(date.shortDateString), which is used to calculate your Adaptive Maintenance Energy.")
        }
    }

    var typePicker: some View {
        var picker: some View {
            Picker("", selection: Binding<Bool>(
                get: { isCustom },
                set: { newValue in
                    withAnimation {
                        isCustom = newValue
                        customInput = DoubleInput(double: 0.8)
                        value = -0.8
                        isGain = false
                        setIsDirty()
                    }
                }
            )) {
//                Text("Use Weights").tag(false)
//                Text("Enter Manually").tag(true)
                Text("Weights").tag(false)
                Text("Manual").tag(true)
            }
            .pickerStyle(.segmented)
            .disabled(!isEditing)
            .listRowSeparator(.hidden)
        }
        
        var description: String {
            switch isCustom {
            case true: "Enter your weight change manually."
            case false: "Use your starting and ending weights to calculate your weight change."
            }
        }
        return Section {
            picker
            Text(description)
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
        WeightChangeForm(date: MockPastDate)
    }
}

#Preview("DemoView") {
    DemoView()
}
