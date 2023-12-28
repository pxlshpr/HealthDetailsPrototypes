import SwiftUI
import SwiftSugar

struct MaintenanceForm: View {
    
    @Environment(\.dismiss) var dismiss

    @State var maintenancetype: MaintenanceType = .adaptive
    @State var value: Double = 3225
    @State var adaptiveValue: Double = 3225
    @State var estimatedValue: Double = 2856

    @State var showingMaintenanceInfo = false
    
    let pastDate: Date?
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    
    @Binding var isPresented: Bool
    
    init(pastDate: Date? = nil, isPresented: Binding<Bool> = .constant(true)) {
        self.pastDate = pastDate
        _isPresented = isPresented
        _isEditing = State(initialValue: pastDate == nil)
    }
    
    var body: some View {
        NavigationView {
            List {
                notice
                valuePicker
                adaptiveLink
                estimatedLink
                explanation
            }
            .navigationTitle("Maintenance Energy")
            .toolbar { toolbarContent }
            .navigationBarBackButtonHidden(isEditing && isPast)
        }
        .sheet(isPresented: $showingMaintenanceInfo) {
            MaintenanceInfo()
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
            AdaptiveMaintenanceForm(pastDate: pastDate, isPresented: $isPresented)
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
                isPresented: $isPresented
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
                }
                
                isDirty = maintenancetype != .adaptive
            }
        )
        
        return Section {
            Picker("", selection: binding) {
                ForEach(MaintenanceType.allCases, id: \.self) {
                    Text($0.name).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(EmptyView())
            .disabled(!isEditing)
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
        return Section(footer: footer) {
            Text("Your Maintenance Energy (also known as your Total Daily Energy Expenditure or TDEE) is the dietary energy you would need to consume daily to maintain your weight.\n\nIt can be used to create energy goals that target a desired change in your weight.\n\nThere are two ways you can calculate it.")
        }
    }
}

#Preview("Current") {
    MaintenanceForm()
}

#Preview("Past") {
    MaintenanceForm(pastDate: MockPastDate)
}
