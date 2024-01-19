import SwiftUI
import PrepShared
import SwiftUIIntrospect

struct MeasurementForm: View {
    
    @Environment(\.dismiss) var dismiss

    @Bindable var settingsProvider: SettingsProvider

    let type: MeasurementType
    let date: Date
    @State var time = Date.now
    
    @State var doubleInput = DoubleInput(automaticallySubmitsValues: true)
    @State var intInput = IntInput(automaticallySubmitsValues: true)
    
    @State var isDirty: Bool = false
    @State var dismissDisabled: Bool = false
    @State var hasFocusedCustom: Bool = false

    let add: (Int, Double, Date) -> ()
    
    init(
        type: MeasurementType,
        date: Date? = nil,
        settingsProvider: SettingsProvider,
        add: @escaping (Int, Double, Date) -> ()
    ) {
        self.date = (date ?? Date.now).startOfDay
        self.type = type
        self.add = add
        self.settingsProvider = settingsProvider
    }
    
    var body: some View {
        NavigationView {
            form
                .navigationTitle(type.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
        }
        .interactiveDismissDisabled(dismissDisabled)
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    var form: some View {
        Form {
            dateTimeSection
            manualSection
        }
    }
    
    func setDismissDisabled() {
        dismissDisabled = isDirty
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add") {
                    add(intInput.int ?? 0, doubleInput.double ?? 0, time)
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
    
    func setIsDirty() {
        isDirty = !(doubleInput.double == nil && intInput.int == nil)
    }
    
    //MARK: - Sections

    var manualSection: some View {
        MeasurementInputSection(
            type: type,
            settingsProvider: settingsProvider,
            doubleInput: $doubleInput,
            intInput: $intInput,
            hasFocused: $hasFocusedCustom,
            handleChanges: setIsDirty
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
}
