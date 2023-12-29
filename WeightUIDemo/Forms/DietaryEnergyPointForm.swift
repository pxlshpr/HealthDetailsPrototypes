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
        Form {
            notice
            dateSection
            picker
            if type == .custom {
                customSection
            }
            explanation
        }
        .navigationTitle("Dietary Energy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .alert("Enter your dietary energy", isPresented: $showingAlert) {
            TextField("kcal", text: customInput.binding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCustomValue)
            Button("Cancel") { customInput.cancel() }
        }
        .sheet(isPresented: $showingInfo) {
            AdaptiveDietaryEnergyInfo()
        }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .navigationBarBackButtonHidden(isPast && isEditing)
        .interactiveDismissDisabled(isPast && isEditing && isDirty)
    }
    
    var dateSection: some View {
        Section {
            HStack {
                Text("Date")
                Spacer()
                Text(dateString)
            }
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
    
    var bottomValue: some View {
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
                ZStack {
                    
                    /// dummy text placed to ensure height stays consistent
                    Text("0")
                        .font(LargeNumberFont)
                        .opacity(0)

                    Text(type == .custom ? "Not Set" : "Not Included")
                        .font(LargeUnitFont)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, BottomValueHorizontalPadding)
        .padding(.vertical, BottomValueVerticalPadding)
        .background(.bar)
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
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
        InputSection(
            name: "Dietary Energy",
            valueString: Binding<String?>(
                get: { value?.formattedEnergy },
                set: { _ in }
            ),
            showingAlert: $showingAlert,
            isDisabled: Binding<Bool>(
                get: { !isEditing },
                set: { _ in }
            ),
            unitString: "kcal"
        )
    }
//    var customSection: some View {
//        
//        Section {
//            Button {
//                showingAlert = true
//            } label: {
//                Text("\(value != nil ? "Edit" : "Set") Dietary Energy")
//            }
//            .disabled(!isEditing)
//        }
//    }
    
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
                setType(to: newValue)
            }
        )
        
        func setType(to newValue: DietaryEnergyPointType) {
            withAnimation {
                type = newValue
                self.value = value(for: newValue)
            }
            if newValue == .custom {
                showingAlert = true
            }
            setIsDirty()
        }
        
        var picker: some View {
            Picker(selection: binding) {
                ForEach(DietaryEnergyPointType.allCases) {
                    Text($0.name).tag($0)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)
            .foregroundStyle(isEditing ? .primary : .secondary)
            .disabled(!isEditing)
        }

        var list: some View {
            func cell(for type: DietaryEnergyPointType) -> some View {
                @ViewBuilder
                var image: some View {
                    switch type {
                    case .healthKit:
                        Image("AppleHealthIcon")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color(.systemGray3), lineWidth: 0.5)
                            )
                    case .fasted:
                        Text("0")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(.label))
                            .monospaced()
                            .frame(width: 24, height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .foregroundStyle(Color(.systemGray4))
                            )
                    default:
                        Image(systemName: type.image)
                            .scaleEffect(type.imageScale)
                            .foregroundStyle(Color(.label))
                            .frame(width: 24, height: 24)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .foregroundStyle(Color(.systemGray4))
                            )
                    }
                }
                
                var checkmark: some View {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .opacity(self.type == type ? 1 : 0)
                        .animation(.none, value: self.type)
                }
                
                var name: some View {
                    Text(type.name)
                        .foregroundStyle(isDisabled ? Color(.secondaryLabel) : Color(.label))
                }
                
                return HStack {
                    image
                    name
                    Spacer()
                    checkmark
                }

            }
            return ForEach(DietaryEnergyPointType.allCases) { type in
                Button {
                    setType(to: type)
                } label: {
                    cell(for: type)
                }
            }
        }
        return Section {
//            picker
            list
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
