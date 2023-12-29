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

    let pastDate: Date?
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    init(
        pastDate: Date? = nil,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.pastDate = pastDate
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
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
        .alert("Enter your weight \(isGain ? "gain" : "loss")", isPresented: $showingAlert) {
            TextField("kg", text: customInput.binding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCustomValue)
            Button("Cancel") { customInput.cancel() }
        }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isPast && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    func setDismissDisabled() {
        dismissDisabled = isPast && isEditing && isDirty
    }

    var bottomValue: some View {
        BottomValue(
            value: $value,
            valueString: Binding<String?>(
                get: { valueAsString },
                set: { _ in }
            ),
            isDisabled: Binding<Bool>(
                get: { !isEditing },
                set: { _ in }
            ),
            unitString: "kg"
        )
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
            isPast: isPast,
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
            Section {
                NavigationLink {
                    WeightChangePointForm(
                        pastDate: pastDate,
                        isPresented: $isPresented,
                        dismissDisabled: $dismissDisabled,
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
                        dismissDisabled: $dismissDisabled,
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
            Section("Weight Change") {
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
                Text("Use Weights").tag(false)
                Text("Enter Manually").tag(true)
            }
            .pickerStyle(.segmented)
            .disabled(!isEditing)
            .listRowSeparator(.hidden)
        }
        
        var description: String {
            switch isCustom {
            case true: "Enter your weight change manually."
            case false: "Use your current and previous weights to calculate your weight change."
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
        WeightChangeForm(pastDate: MockPastDate)
    }
}

#Preview("DemoView") {
    DemoView()
}
