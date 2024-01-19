import SwiftUI
import SwiftSugar
import PrepShared

struct MaintenanceForm: View {
    
    @Bindable var healthProvider: HealthProvider
    @Binding var isPresented: Bool

    let date: Date
    
    @State var estimate: HealthDetails.Maintenance.Estimate
    @State var adaptive: HealthDetails.Maintenance.Adaptive
    @State var maintenancetype: MaintenanceType
    @State var maintenanceInKcal: Double?
    @State var useEstimateAsFallback: Bool

    @State var showingMaintenanceInfo = false
    
    let saveHandler: (HealthDetails.Maintenance, Bool) -> ()
    
    init(
        date: Date,
        maintenance: HealthDetails.Maintenance,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        saveHandler: @escaping (HealthDetails.Maintenance, Bool) -> ()
    ) {
        self.date = date
        self.saveHandler = saveHandler
        self.healthProvider = healthProvider
        _isPresented = isPresented

        _maintenanceInKcal = State(initialValue: maintenance.kcal)
        _maintenancetype = State(initialValue: maintenance.type)
        _useEstimateAsFallback = State(initialValue: maintenance.useEstimateAsFallback)
        _estimate = State(initialValue: maintenance.estimate)
        _adaptive = State(initialValue: maintenance.adaptive)
    }
    
    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            maintenance: healthProvider.healthDetails.maintenance,
            healthProvider: healthProvider,
            isPresented: isPresented,
            saveHandler: healthProvider.saveMaintenance
        )
    }
    
    var body: some View {
        List {
            dateSection
            about
            valuePicker
            adaptiveLink
            estimateLink
            fallbackToggle
            explanation
        }
        .navigationTitle("Maintenance Energy")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showingMaintenanceInfo) {
            MaintenanceInfo()
        }
        .safeAreaInset(edge: .bottom) { bottomValue }
    }
    
    var energyUnit: EnergyUnit { healthProvider.settingsProvider.energyUnit }
    var energyUnitString: String { healthProvider.settingsProvider.energyUnit.abbreviation }

    var bottomValue: some View {
        var value: Double? {
            guard let maintenanceInKcal else { return nil }
            return EnergyUnit.kcal.convert(maintenanceInKcal, to: energyUnit)
        }
        
        return MeasurementBottomBar(
            double: Binding<Double?>(
                get: { value },
                set: { _ in }
            ),
            doubleString: Binding<String?>(
                get: { value?.formattedEnergy },
                set: { _ in }
            ),
            doubleUnitString: energyUnitString
        )
    }
    
    var fallbackToggle: some View {
        
        var footer: some View {
//            Text("Your Estimated Maintenance Energy will be used when there is not enough Weight or Dietary Energy data to calculate your Adaptive Maintenance.")
            Text("The Estimate will be used as a fallback when the Adaptive calcuation cannot be made due to a lack of data.")
        }
        
        let binding = Binding<Bool>(
            get: { useEstimateAsFallback },
            set: { newValue in
                withAnimation {
                    useEstimateAsFallback = newValue
                }
                handleChanges()
            }
        )
        
        var title: String {
//            "Use Estimate when Adaptive calculation cannot be made"
            "Use Estimate as fallback"
        }
        
        return Group {
            if maintenancetype == .adaptive {
                Section(footer: footer) {
                    Toggle(title, isOn: binding)
                        .foregroundColor(.primary)
                }
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

    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isPresented = false
            } label: {
                CloseButtonLabel()
            }
        }
    }
    
    func save(_ shouldResync: Bool) {
        saveHandler(maintenance, shouldResync)
    }
    
    var maintenance: HealthDetails.Maintenance {
        .init(
            type: maintenancetype,
            kcal: maintenanceInKcal,
            adaptive: adaptive,
            estimate: estimate,
            useEstimateAsFallback: useEstimateAsFallback,
            hasConfigured: true
        )
    }

    var adaptiveLink: some View {
        var label: some View {
            HStack {
                Text("Adaptive")
                Spacer()
                if let kcal = adaptive.kcal {
                    Text(healthProvider.settingsProvider.energyString(kcal))
                } else {
                    Text(NotSetString)
                        .foregroundStyle(.secondary)
                }
            }
        }
        
        var destination: some View {
            AdaptiveMaintenanceForm(
                date: date,
                adaptive: adaptive,
                healthProvider: healthProvider,
                isPresented: $isPresented,
                saveHandler: { adaptive, shouldResync in
                    self.adaptive = adaptive
                    handleChanges(shouldResync)
                }
            )
        }
        
        var navigationViewLink: some View {
            NavigationLink {
                destination
            } label: {
                label
            }

        }
        return Section {
            navigationViewLink
        }
    }

    var estimateLink: some View {
        var label: some View {
            HStack {
                Text("Estimate")
                Spacer()
                if let kcal = estimate.kcal {
                    Text(healthProvider.settingsProvider.energyString(kcal))
                } else {
                    Text(NotSetString)
                        .foregroundStyle(.secondary)
                }
            }
        }
        
        var destination: some View {
            EstimatedMaintenanceForm(
                date: date,
                estimate: estimate,
                healthProvider: healthProvider,
                isPresented: $isPresented,
                saveHandler: { estimate, shouldResync in
                    self.estimate = estimate
                    handleChanges(shouldResync)
                }
            )
        }
        
        var navigationViewLink: some View {
            NavigationLink {
                destination
            } label: {
                label
            }

        }
        return Section {
            navigationViewLink
        }
    }

    func handleChanges(_ shouldResync: Bool = false) {
        
        let maintenanceInKcal: Double? = switch maintenancetype {
        case .adaptive:
            if let kcal = adaptive.kcal {
                kcal
            } else if useEstimateAsFallback {
                estimate.kcal
            } else {
                nil
            }
        case .estimated:
            estimate.kcal
        }
        withAnimation {
            self.maintenanceInKcal = maintenanceInKcal
        }

        save(shouldResync)
    }
    
    var valuePicker: some View {
        let binding = Binding<MaintenanceType>(
            get: { maintenancetype },
            set: { newValue in
                withAnimation {
                    maintenancetype = newValue
                }
                handleChanges()
            }
        )
        
        var pickerRow: some View {
            Picker("", selection: binding) {
                ForEach(MaintenanceType.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .listRowSeparator(.hidden)
        }
        
        var description: String {
            switch maintenancetype {
            case .adaptive:
                "Using the Adaptive calculation."
            case .estimated:
                "Using your Estimated calculation."
            }
        }

        return Section {
            pickerRow
            Text(description)
        }
    }
 
    var about: some View {
        var footer: some View {
            Button {
                showingMaintenanceInfo = true
            } label: {
                Text("Learn more…")
                    .font(.footnote)
            }
        }
        
        return Section(footer: footer) {
            Text("Your Maintenance Energy (also known as your Total Daily Energy Expenditure or TDEE) is the dietary energy you would need to consume daily to maintain your weight.\n\nThere are two ways you can calculate it.")
        }
    }
    
    var explanation: some View {
        var header: some View {
            Text("Usage")
                .formTitleStyle()
        }
        return Section(header: header) {
            Text("Your Maintenance Energy is used to create energy goals that target a desired change in your weight.\n\nFor example, you could create an energy goal that targets a 500 kcal deficit in weight per week, which would amount to about 0.2 to 0.5 kg.")
        }
    }
}
