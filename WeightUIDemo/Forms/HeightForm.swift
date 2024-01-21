import SwiftUI
import SwiftSugar
import PrepShared

struct HeightForm: View {

    @Bindable var healthProvider: HealthProvider
    
    let date: Date

    @State var heightInCm: Double?
    @State var measurements: [HeightMeasurement]
    @State var deletedHealthKitMeasurements: [HeightMeasurement]
    
    @State var dailyMeasurementType: DailyMeasurementType
    @State var isSynced: Bool

    @State var showingForm = false

    @Binding var isPresented: Bool
    
    let saveHandler: (HealthDetails.Height) -> ()

    init(
        date: Date,
        height: HealthDetails.Height,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        save: @escaping (HealthDetails.Height) -> ()
    ) {
        self.date = date
        self.saveHandler = save
        self.healthProvider = healthProvider
        _isPresented = isPresented
                
        _heightInCm = State(initialValue: height.heightInCm)
        _measurements = State(initialValue: height.measurements)
        _deletedHealthKitMeasurements = State(initialValue: height.deletedHealthKitMeasurements)
        
        _dailyMeasurementType = State(initialValue: healthProvider.settingsProvider.settings.dailyMeasurementType(for: .weight))
        _isSynced = State(initialValue: healthProvider.settingsProvider.heightIsHealthKitSynced)
    }

    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            height: healthProvider.healthDetails.height,
            healthProvider: healthProvider,
            isPresented: isPresented,
            save: healthProvider.saveHeight(_:)
        )
    }
    
    var body: some View {
        Form {
            dateSection
            measurementsSections
            dailyMeasurementTypePicker
            syncSection
            explanation
        }
        .navigationTitle("Height")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingForm) { measurementForm }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .onChange(of: isSynced, isSyncedChanged)
    }
    
    var dailyMeasurementTypePicker: some View {
        let binding = Binding<DailyMeasurementType>(
            get: { dailyMeasurementType },
            set: { newValue in
                withAnimation {
                    dailyMeasurementType = newValue
                    healthProvider.setDailyMeasurementType(for: .height, to: newValue)
                    handleChanges()
                }
            }
        )
        
        var pickerRow: some View {
            Picker("", selection: binding) {
                ForEach(DailyMeasurementType.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
        }

        var description: String {
            dailyMeasurementType.description(for: .height)
        }

        var header: some View {
            Text("Handling Multiple Measurements")
        }

        return Section(header: header) {
            pickerRow
            Text(description)
        }
    }
    
    func isSyncedChanged(old: Bool, new: Bool) {
        healthProvider.setHealthKitSyncing(for: .height, to: new)
    }
    
    var heightUnit: HeightUnit {
        healthProvider.settingsProvider.heightUnit
    }
    
    var calculatedHeightInCm: Double? {
        measurements.dailyMeasurement(for: dailyMeasurementType)
    }

    var bottomValue: some View {
        
        var double: Double? {
            guard let heightInCm else { return nil }
            return HeightUnit.cm
                .doubleComponent(heightInCm, in: heightUnit)
        }
        
        var int: Int? {
            guard let heightInCm else { return nil }
            return HeightUnit.cm
                .intComponent(heightInCm, in: heightUnit)
        }
        
        var intUnitString: String? { heightUnit.intUnitString }
        var doubleUnitString: String { heightUnit.doubleUnitString }
        
        return MeasurementBottomBar(
            int: Binding<Int?>(
                get: { int }, set: { _ in }
            ),
            intUnitString: intUnitString,
            double: Binding<Double?>(
                get: { double }, set: { _ in }
            ),
            doubleString: Binding<String?>(
                get: { double?.cleanHealth }, set: { _ in }
            ),
            doubleUnitString: doubleUnitString
        )
    }
    
    var measurementForm: some View {
        MeasurementForm(
            type: .height,
            date: date,
            settingsProvider: healthProvider.settingsProvider
        ) { int, double, time in
            let heightInCm = heightUnit.convert(int, double, to: .cm)
            let measurement = HeightMeasurement(date: time, heightInCm: heightInCm)
            measurements.append(measurement)
            measurements.sort()
            handleChanges()
        }
    }
    
    var syncSection: some View {
        SyncSection(
            healthDetail: .height,
            isSynced: $isSynced,
            handleChanges: handleChanges
        )
    }
    
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isPresented = false
            } label: {
                CloseButtonLabel()
            }
        }
    }
    
    var explanation: some View {
        var header: some View {
            Text("Usage")
                .formTitleStyle()
        }

        return Section(header: header) {
            VStack(alignment: .leading) {
                Text("Your height is used in certain equations when calculating your:")
                dotPoint("Resting Energy")
                dotPoint("Lean Body Mass")
            }
        }
    }
    
    var dateSection: some View {
        Section {
            HStack {
                Text("Date")
                Spacer()
                Text(date.shortDateString)
            }
        }
    }
    
    var measurementsSections: some View {
        MeasurementsSections<HeightUnit>(
            settingsProvider: healthProvider.settingsProvider,
            measurements: Binding<[any Measurable]>(
                get: { measurements },
                set: { newValue in
                    guard let measurements = newValue as? [HeightMeasurement] else { return }
                    self.measurements = measurements
                }
            ),
            deletedHealthKitMeasurements: Binding<[any Measurable]>(
                get: { deletedHealthKitMeasurements },
                set: { newValue in
                    guard let measurements = newValue as? [HeightMeasurement] else { return }
                    self.deletedHealthKitMeasurements = measurements
                }
            ),
            showingForm: $showingForm,
            handleChanges: handleChanges
        )
    }
    
    func save() {
        saveHandler(height)
    }
    
    func handleChanges() {
        heightInCm = calculatedHeightInCm
        save()
    }

    var height: HealthDetails.Height {
        HealthDetails.Height(
            heightInCm: calculatedHeightInCm,
            measurements: measurements,
            deletedHealthKitMeasurements: deletedHealthKitMeasurements
        )
    }
}

#Preview {
    DemoView()
}
