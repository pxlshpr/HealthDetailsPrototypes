import SwiftUI
import SwiftSugar
import PrepShared

struct LeanBodyMassForm: View {
    
    @Bindable var healthProvider: HealthProvider
    @Binding var isPresented: Bool
    
    let date: Date

    @State var leanBodyMassInKg: Double?
    @State var fatPercentage: Double?
    @State var dailyValueType: DailyValueType
    @State var measurements: [LeanBodyMassMeasurement]
    @State var deletedHealthKitMeasurements: [LeanBodyMassMeasurement]
    @State var isSynced: Bool = true
    
    @State var showingForm = false
    
    let saveHandler: (HealthDetails.LeanBodyMass) -> ()

    init(
        date: Date,
        leanBodyMass: HealthDetails.LeanBodyMass,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        save: @escaping (HealthDetails.LeanBodyMass) -> ()
    ) {
        self.date = date
        self.saveHandler = save
        self.healthProvider = healthProvider
        _isPresented = isPresented
        
        _leanBodyMassInKg = State(initialValue: leanBodyMass.leanBodyMassInKg)
        _measurements = State(initialValue: leanBodyMass.measurements)
        _dailyValueType = State(initialValue: healthProvider.settingsProvider.settings.dailyValueType(for: .leanBodyMass))
        _deletedHealthKitMeasurements = State(initialValue: leanBodyMass.deletedHealthKitMeasurements)
        _isSynced = State(initialValue: healthProvider.settingsProvider.leanBodyMassIsHealthKitSynced)
    }
    
    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            leanBodyMass: healthProvider.healthDetails.leanBodyMass,
            healthProvider: healthProvider,
            isPresented: isPresented,
            save: healthProvider.saveLeanBodyMass
        )
    }

    var body: some View {
        Form {
            dateSection
            measurementsSections
            convertedMeasurementsSections
            dailyValuePicker
            syncSection
            explanation
        }
        .navigationTitle("Lean Body Mass")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingForm) { measurementForm }
        .safeAreaInset(edge: .bottom) { bottomValue }
        .onChange(of: isSynced, isSyncedChanged)
    }
    
    var convertedMeasurementsSections: some View {
        var header: some View {
            Text("Converted Fat Percentages")
        }
        var footer: some View {
            Text("These measurements have been converted from your fat percentage measurements using your weight for the day.")
        }
        
        return Section(header: header, footer: footer) {
            HStack {
                Text("11:20 pm")
                Spacer()
                Text("71.5 kg")
            }
            .foregroundStyle(.secondary)
        }
    }
    
    func isSyncedChanged(old: Bool, new: Bool) {
        healthProvider.setHealthKitSyncing(for: .leanBodyMass, to: new)
    }

    //MARK: - Sections
    
    var explanation: some View {
        var header: some View {
            Text("Usage")
                .formTitleStyle()
        }
        
        return Section(header: header) {
            VStack(alignment: .leading) {
                Text("Your lean body mass is the weight of your body minus your body fat (adipose tissue). It is used when:")
                dotPoint("Creating goals. For example, you could create a protein goal relative to your lean body mass instead of your weight.")
                dotPoint("Calculating your Resting Energy using certain equations.")
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
    
    var bodyMassUnit: BodyMassUnit {
        healthProvider.settingsProvider.bodyMassUnit
    }
    
    var bottomValue: some View {
        var intUnitString: String? { bodyMassUnit.intUnitString }
        var doubleUnitString: String { bodyMassUnit.doubleUnitString }
        
        var double: Double? {
            guard let leanBodyMassInKg else { return nil }
            return BodyMassUnit.kg
                .doubleComponent(leanBodyMassInKg, in: bodyMassUnit)
        }
        
        var int: Int? {
            guard let leanBodyMassInKg else { return nil }
            return BodyMassUnit.kg
                .intComponent(leanBodyMassInKg, in: bodyMassUnit)
        }
        
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

//        return HStack(alignment: .firstTextBaseline, spacing: 5) {
//            if let fatPercentage {
//                Text("\(fatPercentage.roundedToOnePlace)")
//                    .contentTransition(.numericText(value: fatPercentage))
//                    .font(LargeNumberFont)
//                    .foregroundStyle(.primary)
//                Text("% fat")
//                    .font(LargeUnitFont)
//                    .foregroundStyle(.secondary)
//            }
//            Spacer()
//            MeasurementBottomText(
//                int: Binding<Int?>(
//                    get: { int }, set: { _ in }
//                ),
//                intUnitString: intUnitString,
//                double: Binding<Double?>(
//                    get: { double }, set: { _ in }
//                ),
//                doubleString: Binding<String?>(
//                    get: { double?.cleanHealth }, set: { _ in }
//                ),
//                doubleUnitString: doubleUnitString
//            )
//        }
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
    
    //MARK: - Rewrite
    var measurementForm: some View {
        LeanBodyMassMeasurementForm(healthProvider: healthProvider) { measurement in
            measurements.append(measurement)
            //TODO: Add a fat percentage measurement based on the latest weight – with a source of .leanBodyMass
            measurements.sort()
            handleChanges()
        }
    }
    
    var dailyValuePicker: some View {
        let binding = Binding<DailyValueType>(
            get: { dailyValueType },
            set: { newValue in
                withAnimation {
                    dailyValueType = newValue
                    healthProvider.setDailyValueType(for: .leanBodyMass, to: newValue)
                    handleChanges()
                }
            }
        )
        
        var pickerRow: some View {
            Picker("", selection: binding) {
                ForEach(DailyValueType.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
        }

        var description: String {
            dailyValueType.description(for: .leanBodyMass)
        }

        var header: some View {
            Text("Handling Multiple Measurements")
        }

        return Section(header: header) {
            pickerRow
            Text(description)
        }
    }
    
    var syncSection: some View {
        SyncSection(
            healthDetail: .leanBodyMass,
            isSynced: $isSynced,
            handleChanges: handleChanges
        )
    }
    
    var measurementsSections: some View {
        MeasurementsSections<BodyMassUnit>(
            settingsProvider: healthProvider.settingsProvider,
            measurements: Binding<[any Measurable]>(
                get: { measurements },
                set: { newValue in
                    guard let measurements = newValue as? [LeanBodyMassMeasurement] else { return }
                    self.measurements = measurements
                }
            ),
            deletedHealthKitMeasurements: Binding<[any Measurable]>(
                get: { deletedHealthKitMeasurements },
                set: { newValue in
                    guard let measurements = newValue as? [LeanBodyMassMeasurement] else { return }
                    self.deletedHealthKitMeasurements = measurements
                }
            ),
            showingForm: $showingForm,
            handleChanges: handleChanges
        )
    }
    
    //MARK: - Actions
    
    func save() {
        saveHandler(leanBodyMass)
    }
    
    func handleChanges() {
        leanBodyMassInKg = calculatedLeanBodyMassInKg
        save()
    }
    
    //MARK: - Convenience
    
    var calculatedLeanBodyMassInKg: Double? {
        measurements.dailyValue(for: dailyValueType)
    }
    
//    var calculatedFatPercentage: Double? {
//        //TODO: Rewrite this
//        switch dailyValueType {
//        case .average:
//            measurements.compactMap { $0.fatPercentage }.average
//        case .last:
//            measurements.last?.fatPercentage
//        case .first:
//            measurements.first?.fatPercentage
//        }
//    }
    
    var leanBodyMass: HealthDetails.LeanBodyMass {
        HealthDetails.LeanBodyMass(
            leanBodyMassInKg: calculatedLeanBodyMassInKg,
//            fatPercentage: calculatedFatPercentage,
            measurements: measurements,
            deletedHealthKitMeasurements: deletedHealthKitMeasurements
        )
    }
}

struct LeanBodyMassFormPreview: View {
    @State var healthProvider: HealthProvider? = nil
    
    @ViewBuilder
    var body: some View {
        if let healthProvider {
            NavigationView {
                LeanBodyMassForm(healthProvider: healthProvider)
            }
        } else {
            Color.clear
                .task {
                    var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(Date.now)
                    healthDetails.weight = .init(
                        weightInKg: 95,
                        measurements: [.init(date: Date.now, weightInKg: 95)]
                    )
                    let settings = await fetchSettingsFromDocuments()
                    let healthProvider = HealthProvider(
                        healthDetails: healthDetails,
                        settingsProvider: SettingsProvider(settings: settings)
                    )
                    await MainActor.run {
                        self.healthProvider = healthProvider
                    }
                }
        }
    }
}

#Preview("Form") {
    LeanBodyMassFormPreview()
}

#Preview("Demo") {
    DemoView()
}
