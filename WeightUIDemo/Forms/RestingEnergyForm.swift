import SwiftUI

struct RestingEnergyForm: View {

    @Environment(\.dismiss) var dismiss

    @State var value: Double? = 2798

    @State var source: RestingEnergySource = .equation
    @State var equation: RestingEnergyEquation = .mifflinStJeor
    
    @State var intervalType: HealthIntervalType = .average
    @State var interval: HealthInterval = .init(3, .day)

    @State var applyCorrection: Bool = true
    @State var correctionType: CorrectionType = .divide
    @State var correction: Double? = 2

    @State var showingAlert = false
    @State var customValue: Double? = 2798
    @State var customValueTextAsDouble: Double? = 2798
    @State var customValueText: String = "2798"
    
    @State var includeTrailingPeriod: Bool = false
    @State var includeTrailingZero: Bool = false
    @State var numberOfTrailingZeros: Int = 0

    @State var showingCorrectionAlert = false
    @State var correctionTextAsDouble: Double? = 2
    @State var correctionText: String = "2"

    @State var showingEquationsInfo = false
    @State var showingHealthIntervalInfo = false
    
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
            sourceSection
            switch source {
            case .userEntered:
                customSection
            case .equation:
                equationSection
                variablesSections
            case .healthKit:
                intervalTypeSection
                if intervalType == .average {
                    intervalSection
                }
                correctionSection
            }
            explanation
        }
        .navigationTitle("Resting Energy")
        .navigationBarBackButtonHidden(isEditing && isPast)
        .toolbar { toolbarContent }
        .alert("Enter your Resting", isPresented: $showingAlert) {
            TextField("kcal", text: customValueTextBinding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCustomValue)
            Button("Cancel") { }
        }
        .alert("Enter a correction", isPresented: $showingCorrectionAlert) {
            TextField(correctionType.textFieldPlaceholder, text: correctionTextBinding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCorrection)
            Button("Cancel") { }
        }
        .sheet(isPresented: $showingEquationsInfo) { equationExplanations }
        .sheet(isPresented: $showingHealthIntervalInfo) {
            HealthIntervalInfo(isRestingEnergy: true)
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
    
    var equationExplanations: some View {
        RestingEnergyEquationsInfo()
    }
}

#Preview("Current") {
    NavigationView {
        RestingEnergyForm()
    }
}

#Preview("Past") {
    NavigationView {
        RestingEnergyForm(pastDate: MockPastDate)
    }
}
