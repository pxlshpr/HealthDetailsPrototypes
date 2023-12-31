import SwiftUI

struct MeasurementForm: View {
    
    @Environment(\.dismiss) var dismiss
    @State var source: LeanBodyMassSource = .fatPercentage
        
    @State var time = Date.now

    @State var value: Double? = 72.0
    @State var customInput = DoubleInput(double: 72)
    
    @State var showingAlert = false

    let date: Date
    @State var isDirty: Bool = false

    @State var dismissDisabled: Bool = false
    
    let healthDetail: HealthDetail
    
    init(healthDetail: HealthDetail, date: Date? = nil) {
        self.date = (date ?? Date.now).startOfDay
        self.healthDetail = healthDetail
        let value: Double = healthDetail == .weight ? 72 : 177
        _value = State(initialValue: value)
        _customInput = State(initialValue: DoubleInput(double: value))
    }

    var body: some View {
        NavigationView {
            form
                .navigationTitle(healthDetail.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .safeAreaInset(edge: .bottom) { bottomValue }
        }
        .alert("Enter your \(healthDetail.name)", isPresented: $showingAlert) {
            TextField(unitString, text: customInput.binding)
                .keyboardType(.decimalPad)
            Button("OK", action: submitCustomValue)
            Button("Cancel") {
                customInput.cancel()
            }
        }
        .interactiveDismissDisabled(dismissDisabled)
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    var unitString: String {
        healthDetail == .weight ? "kg" : "cm"
    }
    var form: some View {
        Form {
            dateTimeSection
            customSection
        }
    }
    
    func setDismissDisabled() {
        dismissDisabled = isDirty
    }
    
    var bottomValue: some View {
        BottomValue(
            value: $value,
            valueString: Binding<String?>(
                get: { value?.clean },
                set: { _ in }
            ),
            isDisabled: .constant(false),
            unitString: unitString
        )
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add") {
                    dismiss()
                }
                .fontWeight(.bold)
                .disabled(!isDirty)
            }
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    
    //MARK: - Sections
    var customSection: some View {
        InputSection(
            name: healthDetail.name,
            valueString: Binding<String?>(
                get: { customInput.double?.clean },
                set: { _ in }
            ),
            showingAlert: $showingAlert,
            unitString: unitString
        )
    }
    
    var dateTimeSection: some View {
        Section {
            DatePicker(
                "Date",
                selection: .constant(date),
                displayedComponents: .date
            )
            .disabled(true)
            DatePicker(
                "Time",
                selection: $time,
                displayedComponents: .hourAndMinute
            )
        }
    }
    
    //MARK: - Actions
    
    func submitCustomValue() {
        withAnimation {
            customInput.submitValue()
            value = customInput.double
            setIsDirty()
        }
    }

    func setIsDirty() {
        isDirty = if let value {
            value != 72
        } else {
            false
        }
    }
}


#Preview("Measurement") {
    MeasurementForm(healthDetail: .weight)
}
