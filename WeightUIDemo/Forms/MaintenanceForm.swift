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

    var body: some View {
        NavigationStack {
            List {
                notice
                valuePicker
                adaptiveLink
                estimatedLink
                explanation
            }
            .padding(.top, 0.3) /// Navigation Bar Fix
            .navigationTitle("Maintenance Energy")
            .toolbar { toolbarContent }
            .navigationBarBackButtonHidden(isEditing && isPast)
        }
        .sheet(isPresented: $showingMaintenanceInfo) {
            MaintenanceInfo()
        }
    }
    
    enum AdaptiveRoute {
        case form
    }
    
    enum EstimatedRoute {
        case form
    }
    
    var adaptiveLink: some View {
        Section {
            NavigationLink(value: AdaptiveRoute.form) {
                HStack {
                    Text("Adaptive")
                    Spacer()
                    Text("\(adaptiveValue.formattedEnergy) kcal")
                }
            }
            .navigationDestination(for: AdaptiveRoute.self) { _ in
                AdaptiveMaintenanceForm(pastDate: pastDate, isPresented: $isPresented)
            }
            .disabled(isPast && isEditing)
        }
    }

    var estimatedLink: some View {
        Section {
            NavigationLink(value: EstimatedRoute.form) {
                HStack {
                    Text("Estimated")
                    Spacer()
                    Text("\(estimatedValue.formattedEnergy) kcal")
                }
            }
            .navigationDestination(for: AdaptiveRoute.self) { _ in
                EstimatedMaintenanceForm()
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
    MaintenanceForm(pastDate: MockPastDate)
}

let MockPastDate = Date.now.moveDayBy(-3)

struct TestForm: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(0...100, id: \.self) { i in
                    NavigationLink(value: i) {
                        Text("\(i)")
                    }
                    .navigationDestination(for: Int.self) { i in
                        Text("Hi")
                    }
//                    NavigationLink {
//                        Text("\(i)")
//                    } label: {
//                        Text("\(i)")
//                    }
                }
            }
            .navigationTitle("Hi")
//            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview("Navigation Test") {
    TestForm()
}
