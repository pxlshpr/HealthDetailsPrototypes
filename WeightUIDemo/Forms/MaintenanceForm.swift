import SwiftUI
import SwiftSugar

struct MaintenanceForm: View {
    
    @State var maintenancetype: MaintenanceType = .adaptive
    @State var value: Double? = 3225
    @State var adaptiveValue: Double = 3225
    @State var estimatedValue: Double = 2856

    @State var useEstimatedAsFallback = true

    @State var showingMaintenanceInfo = false
    
    let pastDate: Date?
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    
    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    init(
        pastDate: Date? = nil,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.pastDate = pastDate
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
        _isEditing = State(initialValue: pastDate == nil)
    }
    
    var body: some View {
        List {
            notice
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
    
    @ViewBuilder
    var fallbackToggle: some View {
        if maintenancetype == .adaptive {
            Section {
                Toggle("Use Estimate when Adaptive cannot be calculated", isOn: $useEstimatedAsFallback)
            }
        }
    }
    
    var isPast: Bool {
        pastDate != nil
    }
    
    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(pastDate, isEditing: $isEditing)
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
    
    func save() {
        
    }
    
    func undo() {
        isDirty = false
        maintenancetype = .adaptive
        value = adaptiveValue
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
                Text("\(adaptiveValue.formattedEnergy) kcal")
            }
        }
        
        var destination: some View {
            AdaptiveMaintenanceForm(
                pastDate: pastDate,
                isPresented: $isPresented,
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
                .disabled(isPast && isEditing)
        }
    }

    var estimatedLink: some View {
        var label: some View {
            HStack {
                Text("Estimated")
                Spacer()
                Text("\(estimatedValue.formattedEnergy) kcal")
            }
        }
        
        var destination: some View {
            EstimatedMaintenanceForm(
                pastDate: pastDate,
                isPresented: $isPresented,
                dismissDisabled: $dismissDisabled
            )
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
                .disabled(isPast && isEditing)
        }
    }

    var valuePicker: some View {
        let binding = Binding<MaintenanceType>(
            get: { maintenancetype },
            set: { newValue in
                withAnimation {
                    maintenancetype = newValue
                    value = maintenancetype == .adaptive ? adaptiveValue : estimatedValue
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
    
    var explanation: some View {
        var footer: some View {
            Button {
                showingMaintenanceInfo = true
            } label: {
                Text("Learn more…")
                    .font(.footnote)
            }
        }
        
        var header: some View {
            Text("About Maintenance Energy")
                .formTitleStyle()
        }
        return Section(header: header, footer: footer) {
            Text("Your Maintenance Energy (also known as your Total Daily Energy Expenditure or TDEE) is the dietary energy you would need to consume daily to maintain your weight.\n\nIt can be used to create energy goals that target a desired change in your weight.\n\nThere are two ways you can calculate it.")
        }
    }
}

#Preview("Current") {
    NavigationView {
        MaintenanceForm()
    }
}

#Preview("Past") {
    NavigationView {
        MaintenanceForm(pastDate: MockPastDate)
    }
}
