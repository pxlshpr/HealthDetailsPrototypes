import SwiftUI
import SwiftSugar

struct MaintenanceForm: View {
    
    @Environment(\.dismiss) var dismiss

    @State var maintenancetype: MaintenanceType = .adaptive
    @State var value: Double = 3225
    @State var adaptiveValue: Double = 3225
    @State var estimatedValue: Double = 2856

    @State var showingMaintenanceInfo = false
    
    let isPast: Bool
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    
    init(isPast: Bool = false) {
        self.isPast = isPast
        _isEditing = State(initialValue: !isPast)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                dateSection
                notice
                valuePicker
                adaptiveLink
                estimatedLink
                explanation
            }
            .padding(.top, 0.3) /// Navigation Bar Fix
            .navigationTitle("Maintenance Energy")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .adaptive:     AdaptiveMaintenanceForm()
                case .estimated:    EstimatedMaintenanceForm()
                }
            }
            .navigationBarBackButtonHidden(isEditing && isPast)
        }
        .sheet(isPresented: $showingMaintenanceInfo) {
            MaintenanceInfo()
        }
    }
    
    @ViewBuilder
    var dateSection: some View {
        if isPast {
            Section {
                HStack {
                    Text("Date")
                    Spacer()
                    Text("22 Dec")
                }
            }
        }
    }
    
    @ViewBuilder
    var notice: some View {
        if isPast, !isEditing {
            NoticeSection.legacy
        }
    }
            
    enum Route {
        case adaptive
        case estimated
    }
    
    var adaptiveLink: some View {
        Section {
            NavigationLink(value: Route.adaptive) {
                HStack {
                    Text("Adaptive")
                    Spacer()
                    Text("\(adaptiveValue.formattedEnergy) kcal")
                }
            }
            .disabled(isPast && isEditing)
        }
    }

    var estimatedLink: some View {
        Section {
            NavigationLink(value: Route.estimated) {
                HStack {
                    Text("Estimated")
                    Spacer()
                    Text("\(estimatedValue.formattedEnergy) kcal")
                }
            }
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
                }
                
                isDirty = maintenancetype != .adaptive
            }
        )
        
        return Section("Use") {
            Picker("", selection: binding) {
                ForEach(MaintenanceType.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .disabled(!isEditing)
        }
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            bottomToolbarContent(
                value: value,
                valueString: value.formattedEnergy,
                isDisabled: !isEditing,
                unitString: "kcal"
            )
            topToolbarContent(
                isEditing: $isEditing,
                isDirty: $isDirty,
                isPast: isPast,
                dismissAction: { dismiss() },
                undoAction: undo,
                saveAction: save
            )
        }
    }
    
    func save() {
        
    }
    
    func undo() {
        isDirty = false
//        withAnimation {
            maintenancetype = .adaptive
            value = adaptiveValue
//        }
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
        return Section(footer: footer) {
            Text("Your Maintenance Energy (also known as your Total Daily Energy Expenditure or TDEE) is the dietary energy you would need to consume daily to maintain your weight.\n\nIt may be used when creating energy goals that target a desired change in your weight.")
        }
    }
}

#Preview("Current") {
    MaintenanceForm()
}

#Preview("Past") {
    MaintenanceForm(isPast: true)
}
