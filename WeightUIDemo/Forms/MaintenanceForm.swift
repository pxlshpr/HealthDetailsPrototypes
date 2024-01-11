import SwiftUI
import SwiftSugar
import PrepShared

struct MaintenanceForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    
    @Bindable var healthProvider: HealthProvider
    
    let date: Date
    let initialMaintenance: HealthDetails.Maintenance
    
    @State var estimate: HealthDetails.Maintenance.Estimate
    @State var adaptive: HealthDetails.Maintenance.Adaptive
    @State var maintenancetype: MaintenanceType
    @State var maintenanceInKcal: Double?
    @State var useEstimateAsFallback: Bool

    @State var showingMaintenanceInfo = false
    
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    let saveHandler: (HealthDetails.Maintenance) -> ()
    
    init(
        date: Date,
        maintenance: HealthDetails.Maintenance,
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false),
        saveHandler: @escaping (HealthDetails.Maintenance) -> ()
    ) {
        self.date = date
        self.initialMaintenance = maintenance
        self.saveHandler = saveHandler
        self.healthProvider = healthProvider
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: date.isToday)

        _maintenanceInKcal = State(initialValue: maintenance.kcal)
        _maintenancetype = State(initialValue: maintenance.type)
        _useEstimateAsFallback = State(initialValue: maintenance.useEstimateAsFallback)
        _estimate = State(initialValue: maintenance.estimate)
        _adaptive = State(initialValue: maintenance.adaptive)
    }
    
    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            maintenance: healthProvider.healthDetails.maintenance,
            healthProvider: healthProvider,
            isPresented: isPresented,
            dismissDisabled: dismissDisabled,
            saveHandler: healthProvider.saveMaintenance
        )
    }
    
    var body: some View {
        List {
            notice
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
        .navigationBarBackButtonHidden(isLegacy && isEditing)
        .onChange(of: isEditing) { _, _ in setDismissDisabled() }
        .onChange(of: isDirty) { _, _ in setDismissDisabled() }
    }
    
    func setDismissDisabled() {
        dismissDisabled = isLegacy && isEditing && isDirty
    }
    
    var bottomValue: some View {
        var value: Double? {
            guard let maintenanceInKcal else { return nil }
            return EnergyUnit.kcal.convert(maintenanceInKcal, to: settingsProvider.energyUnit)
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
            doubleUnitString: settingsProvider.energyUnit.abbreviation,
            isDisabled: Binding<Bool>(
                get: { !isEditing },
                set: { _ in }
            )
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
                        .disabled(!isEditing)
                        .foregroundColor(isEditing ? .primary : .secondary)
                }
            }
        }
    }
    
    var isLegacy: Bool {
        date.startOfDay < Date.now.startOfDay
    }
    
    @ViewBuilder
    var notice: some View {
        if isLegacy {
            NoticeSection.legacy(date, isEditing: $isEditing)
        }
    }
    
    var toolbarContent: some ToolbarContent {
        topToolbarContent(
            isEditing: $isEditing,
            isDirty: $isDirty,
            isPast: isLegacy,
            dismissAction: { 
                isPresented = false
            },
            undoAction: undo,
            saveAction: save
        )
    }
    
    func save() {
        saveHandler(maintenance)
    }
    
    var maintenance: HealthDetails.Maintenance {
        .init(
            type: maintenancetype,
            kcal: maintenanceInKcal,
            adaptive: adaptive,
            estimate: estimate,
            useEstimateAsFallback: useEstimateAsFallback
        )
    }
    
    func undo() {
        maintenanceInKcal = initialMaintenance.kcal
        maintenancetype = initialMaintenance.type
        useEstimateAsFallback = initialMaintenance.useEstimateAsFallback
        estimate = initialMaintenance.estimate
        adaptive = initialMaintenance.adaptive
    }

    var adaptiveLink: some View {
        var label: some View {
            HStack {
                Text("Adaptive")
                Spacer()
                if let kcal = adaptive.kcal {
                    Text("\(EnergyUnit.kcal.convert(kcal, to: settingsProvider.energyUnit).formattedEnergy) \(settingsProvider.energyUnit.abbreviation)")
                } else {
                    Text("Not Set")
                        .foregroundStyle(.secondary)
                }
            }
        }
        
        var destination: some View {
            AdaptiveMaintenanceForm(
                date: date,
                adaptive: initialMaintenance.adaptive,
                healthProvider: healthProvider,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled,
                saveHandler: { adaptive in
                    self.adaptive = adaptive
                    handleChanges(forceSave: true)
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
                .disabled(isLegacy && isEditing)
        }
    }

    var estimateLink: some View {
        var label: some View {
            HStack {
                Text("Estimate")
                Spacer()
                if let kcal = estimate.kcal {
                    Text("\(EnergyUnit.kcal.convert(kcal, to: settingsProvider.energyUnit).formattedEnergy) \(settingsProvider.energyUnit.abbreviation)")
                } else {
                    Text("Not Set")
                        .foregroundStyle(.secondary)
                }
            }
        }
        
        var destination: some View {
            EstimatedMaintenanceForm(
                date: date,
                estimate: initialMaintenance.estimate,
                healthProvider: healthProvider,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled,
                saveHandler: { estimate in
                    self.estimate = estimate
                    handleChanges(forceSave: true)
                }
            )
            .environment(settingsProvider)
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
                .disabled(isLegacy && isEditing)
        }
    }

    func handleChanges(forceSave: Bool = false) {
        
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

        setIsDirty()
        if !isLegacy || forceSave {
            save()
        }
    }
    
    func setIsDirty() {
        isDirty = maintenance != initialMaintenance
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
            .disabled(!isEditing)
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

#Preview("Current") {
    NavigationView {
        MaintenanceForm(healthProvider: MockCurrentProvider)
    }
}

#Preview("Past") {
    NavigationView {
        MaintenanceForm(healthProvider: MockPastProvider)
    }
}
