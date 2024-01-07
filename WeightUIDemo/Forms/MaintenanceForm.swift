import SwiftUI
import SwiftSugar

struct MaintenanceForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    
    @Bindable var healthProvider: HealthProvider
    
    let date: Date
    let initialMaintenance: HealthDetails.Maintenance
    
    @State var maintenancetype: MaintenanceType = .adaptive
    @State var valueInKcal: Double? = nil
    @State var adaptiveValueInKcal: Double? = nil
    @State var estimatedValueInKcal: Double? = nil

    @State var useEstimateAsFallback = true

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
//        let _ = Self._printChanges()
        List {
            notice
            about
            valuePicker
            adaptiveLink
            estimatedLink
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
        MeasurementBottomBar(
            double: $valueInKcal,
            doubleString: Binding<String?>(
                get: { valueInKcal?.formattedEnergy },
                set: { _ in }
            ),
            doubleUnitString: "kcal",
            isDisabled: Binding<Bool>(
                get: { !isEditing },
                set: { _ in }
            )
        )
    }
    
    var fallbackToggle: some View {
        
        var footer: some View {
            Text("Your Estimated Maintenance Energy will be used when there is not enough Weight or Dietary Energy data to calculate your Adaptive Maintenance.")
        }
        
        return Group {
            if maintenancetype == .adaptive {
                Section(footer: footer) {
                    Toggle("Use Estimate when Adaptive calculation cannot be made", isOn: $useEstimateAsFallback)
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
        
    }
    
    func undo() {
        isDirty = false
        maintenancetype = .adaptive
        valueInKcal = adaptiveValueInKcal
    }

    enum AdaptiveRoute {
        case form
    }
    
    enum EstimatedRoute {
        case form
    }
    
    var adaptiveLink: some View {
        var label: some View {
            HStack {
                Text("Adaptive")
                Spacer()
                if let adaptiveValueInKcal {
                    Text("\(adaptiveValueInKcal.formattedEnergy) kcal")
                } else {
                    Text("Not Set")
                        .foregroundStyle(.secondary)
                }
            }
        }
        
        var destination: some View {
            AdaptiveMaintenanceForm(
                date: date,
                isPresented: $isPresented,
//                isPresented: .constant(true),
                dismissDisabled: $dismissDisabled
            )
        }
        
        var NavigationViewLink: some View {
            NavigationLink(value: AdaptiveRoute.form) {
                label
            }
            .navigationDestination(for: AdaptiveRoute.self) { _ in
                destination
            }
        }
        
        var navigationViewLink: some View {
            NavigationLink {
                destination
            } label: {
                label
            }

        }
        return Section {
//            NavigationViewLink
            navigationViewLink
                .disabled(isLegacy && isEditing)
        }
    }

    var estimatedLink: some View {
        var label: some View {
            HStack {
                Text("Estimated")
                Spacer()
                if let estimatedValueInKcal {
                    Text("\(estimatedValueInKcal.formattedEnergy) kcal")
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
//                isPresented: .constant(true),
                dismissDisabled: $dismissDisabled
            )
            .environment(settingsProvider)
//            EstimatedMaintenanceForm(
//                healthProvider: healthProvider,
//                isPresented: $isPresented,
//                dismissDisabled: $dismissDisabled
//            )
        }
        
        var NavigationViewLink: some View {
            NavigationLink(value: EstimatedRoute.form) {
                label
            }
            .navigationDestination(for: AdaptiveRoute.self) { _ in
                label
            }
        }
        
        var navigationViewLink: some View {
            NavigationLink {
                destination
            } label: {
                label
            }

        }
        return Section {
//            NavigationViewLink
            navigationViewLink
                .disabled(isLegacy && isEditing)
        }
    }

    var valuePicker: some View {
        let binding = Binding<MaintenanceType>(
            get: { maintenancetype },
            set: { newValue in
                withAnimation {
                    maintenancetype = newValue
                    valueInKcal = maintenancetype == .adaptive ? adaptiveValueInKcal : estimatedValueInKcal
                    isDirty = maintenancetype != .adaptive
                }
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
