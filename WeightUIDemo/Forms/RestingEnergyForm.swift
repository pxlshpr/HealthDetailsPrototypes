import SwiftUI

struct RestingEnergyForm: View {

    @Bindable var provider: HealthProvider
    
    @State var value: Double? = 2798

    @State var source: RestingEnergySource = .equation
    @State var equation: RestingEnergyEquation = .katchMcardle
    
    @State var intervalType: HealthIntervalType = .average
    @State var interval: HealthInterval = .init(3, .day)

    @State var applyCorrection: Bool = true
    @State var correctionType: CorrectionType = .divide

    @State var showingAlert = false
    
    @State var correctionInput = DoubleInput(double: 2)

    @State var showingEquationsInfo = false
    @State var showingRestingEnergyInfo = false
    @State var showingCorrectionAlert = false

    @State var customInput = DoubleInput(double: 2798)
    
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    init(
        provider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.provider = provider
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: provider.isCurrent)
    }
    
    var pastDate: Date? {
        provider.pastDate
    }

    var body: some View {
        Form {
            notice
            explanation
            sourceSection
            switch source {
            case .userEntered:
                customSection
//                EmptyView()
            case .equation:
                equationSection
                variablesSections
            case .healthKit:
                healthSections
            }
        }
        .navigationTitle("Resting Energy")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingEquationsInfo) { equationExplanations }
        .sheet(isPresented: $showingRestingEnergyInfo) {
            RestingEnergyInfo()
        }
        .alert("Enter your Resting Energy", isPresented: $showingAlert) {
            TextField("kcal", text: customInput.binding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCustomValue)
            Button("Cancel") { 
                customInput.cancel()
            }
        }
        .alert("Enter a correction", isPresented: $showingCorrectionAlert) {
            TextField(correctionType.textFieldPlaceholder, text: correctionInput.binding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCorrection)
            Button("Cancel") { correctionInput.cancel() }
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
                get: { value?.formattedEnergy },
                set: { _ in }
            ),
            isDisabled: Binding<Bool>(
                get: { !isEditing },
                set: { _ in }
            ),
            unitString: "kcal"
        )
    }
    
    func submitCorrection() {
        withAnimation {
            correctionInput.submitValue()
            setIsDirty()
        }
    }

    func submitCustomValue() {
        withAnimation {
            customInput.submitValue()
            value = customInput.double
            setIsDirty()
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
    
    var equationExplanations: some View {
        RestingEnergyEquationsInfo()
    }
}

//MARK: - Sections

extension RestingEnergyForm {
    
    var variablesSections: some View {
        EquationVariablesSections(
            healthDetails: Binding<[HealthDetail]>(
                get: { equation.requiredHealthDetails },
                set: { _ in }
            ),
            provider: provider,
            pastDate: pastDate,
            isEditing: $isEditing,
            isPresented: $isPresented,
            dismissDisabled: $dismissDisabled
        )
    }

    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: $isEditing)
        }
    }
    
    var sourceSection: some View {
        let binding = Binding<RestingEnergySource>(
            get: { source },
            set: { newValue in
                withAnimation {
                    source = newValue
                    setIsDirty()
                }
                if source == .userEntered {
                    showingAlert = true
                }
            }
        )
        
        var pickerRow: some View {
            Picker("Resting Energy", selection: binding) {
                ForEach(RestingEnergySource.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .foregroundStyle(controlColor)
            .pickerStyle(.segmented)
            .disabled(isDisabled)
            .listRowSeparator(.hidden)
        }
        
        var descriptionRow: some View {
            var description: String {
                switch source {
                case .healthKit:
                    "Use the Resting Energy data recorded in the Apple Health app."
                case .equation:
                    "Use an equation to calculate your Resting Energy."
                case .userEntered:
                    "Enter the Resting Energy manually."
                }
            }
            
            return Text(description)
        }
        
        return Section {
            pickerRow
            descriptionRow
        }
    }
    
    var healthSections: some View {
        EnergyAppleHealthSections(
            intervalType: $intervalType,
            interval: $interval,
            pastDate: pastDate,
            isEditing: $isEditing,
            applyCorrection: $applyCorrection,
            correctionType: $correctionType,
            correctionInput: $correctionInput,
            setIsDirty: setIsDirty,
            isRestingEnergy: true,
            showingCorrectionAlert: $showingCorrectionAlert
        )
    }

    var explanation: some View {
        var header: some View {
            Text("About Resting Energy")
                .textCase(.none)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(Color(.label))
        }
        
        var footer: some View {
            Button {
                showingRestingEnergyInfo = true
            } label: {
                Text("Learn more…")
                    .font(.footnote)
            }
        }
        
        return Section {
            VStack(alignment: .leading) {
                Text("Your Resting Energy, or your Basal Metabolic Rate (BMR), is the energy your body uses each day while minimally active. You can set it in three ways.")
            }
        }
    }
    
    var customSection: some View {
        InputSection(
            name: "Resting Energy",
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
    
    var equationSection: some View {
        let binding = Binding<RestingEnergyEquation>(
            get: { equation },
            set: { newValue in
                withAnimation {
                    equation = newValue
                    setIsDirty()
                }
            }
        )
        
        @ViewBuilder
        var footer: some View {
            if !isDisabled {
                Button {
                    showingEquationsInfo = true
                } label: {
                    Text("Learn more…")
                        .font(.footnote)
                }
            }
        }
        
        return Section(footer: footer) {
            Picker("Equation", selection: binding) {
                ForEach(RestingEnergyEquation.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.menu)
            .disabled(isDisabled)
            .foregroundStyle(controlColor)
        }
    }
}

//MARK: - Convenience

extension RestingEnergyForm {
    var isDisabled: Bool {
        isPast && !isEditing
    }
    
    var controlColor: Color {
        isDisabled ? .secondary : .primary
    }
    
    var isPast: Bool {
        pastDate != nil
    }
}

//MARK: - Actions

extension RestingEnergyForm {
    func undo() {
        isDirty = false
        source = .equation
        equation = .mifflinStJeor
        intervalType = .average
        interval = .init(3, .day)
        applyCorrection = true
        correctionType = .divide
        correctionInput = DoubleInput(double: 2)
        value = 2798
        customInput = DoubleInput(double: 2798)
    }
    
    func setIsDirty() {
        isDirty = source != .equation
        || equation != .mifflinStJeor
        || intervalType != .average
        || interval != .init(3, .day)
        || applyCorrection != true
        || correctionType != .divide
        || value != 2798
        || correctionInput.double != 2
    }
    
    func save() {
        
    }
}

//MARK: - Previews

#Preview("Current") {
    NavigationView {
        RestingEnergyForm(provider: MockCurrentProvider)
    }
}

#Preview("Past") {
    NavigationView {
        RestingEnergyForm(provider: MockPastProvider)
    }
}

#Preview("Demo") {
    DemoView()
}

public struct CloseButtonLabel: View {
    
    let backgroundStyle: TopButtonLabel.BackgroundStyle
    let forUseOutsideOfNavigationBar: Bool
    
    public init(
        forUseOutsideOfNavigationBar: Bool = false,
        backgroundStyle: TopButtonLabel.BackgroundStyle = .standard
    ) {
        self.forUseOutsideOfNavigationBar = forUseOutsideOfNavigationBar
        self.backgroundStyle = backgroundStyle
    }
    
    public var body: some View {
        TopButtonLabel(
            systemImage: "xmark.circle.fill",
            forUseOutsideOfNavigationBar: forUseOutsideOfNavigationBar,
            backgroundStyle: backgroundStyle
        )
    }
}

import SwiftUI

public struct TopButtonLabel: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let fontSize: CGFloat
    let backgroundStyle: BackgroundStyle
    let systemImage: String
    
    public init(
        systemImage: String,
        forUseOutsideOfNavigationBar: Bool = false,
        backgroundStyle: BackgroundStyle = .standard
    ) {
        self.fontSize = forUseOutsideOfNavigationBar ? 30 : 24
        self.backgroundStyle = backgroundStyle
        self.systemImage = systemImage
    }
    
    public var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: fontSize))
            .symbolRenderingMode(.palette)
            .foregroundStyle(foregroundColor, backgroundColor)
    }
    
    var foregroundColor: Color {
        Color(hex: colorScheme == .light ? "838388" : "A0A0A8")
    }
    
    var backgroundColor: Color {
        switch backgroundStyle {
        case .standard:
#if os(iOS)
            return Color(.quaternaryLabel).opacity(0.5)
#else
            return Color(.quaternaryLabelColor).opacity(0.5)
#endif
//            return Color(hex: colorScheme == .light ? "EEEEEF" : "313135")
        case .forPlacingOverMaterials:
#if os(iOS)
            return colorScheme == .light
            ? Color(hex: "EEEEEF").opacity(0.5)
            : Color(.quaternaryLabel).opacity(0.5)
#else
            return colorScheme == .light
            ? Color(hex: "EEEEEF").opacity(0.5)
            : Color(.quaternaryLabelColor).opacity(0.5)
#endif
        }
    }
    
    public enum BackgroundStyle {
        case standard
        case forPlacingOverMaterials
    }
}

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
