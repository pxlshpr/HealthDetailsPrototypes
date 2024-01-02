import SwiftUI
import PrepShared
import SwiftUIIntrospect

struct MeasurementForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    @Environment(\.dismiss) var dismiss
    
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
        add: @escaping (Int, Double, Date) -> ()
    ) {
        self.date = (date ?? Date.now).startOfDay
        self.type = type
        self.add = add
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
            customSection
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

    var customSection: some View {
        MeasurementInputSection(
            type: type,
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

#Preview("Height (cm)") {
    MeasurementForm(type: .height) { int, double, time in
        
    }
    .environment(SettingsProvider(settings: .init(heightUnit: .cm)))
}

#Preview("Height (ft)") {
    MeasurementForm(type: .height) { int, double, time in
        
    }
    .environment(SettingsProvider(settings: .init(heightUnit: .ft)))
}

#Preview("HeightForm") {
    NavigationView {
        HeightForm(healthProvider: MockCurrentProvider)
            .environment(SettingsProvider(settings: .init(heightUnit: .ft)))
    }
}
