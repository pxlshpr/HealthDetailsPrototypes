import SwiftUI
import SwiftSugar

let LargeNumberFont: Font = .system(.largeTitle, design: .rounded, weight: .bold)
//let LogStartDate = Date(fromDateString: "2023_12_01")!
let LogStartDate = Date(fromDateString: "2022_01_01")!
let DaysStartDate = Date(fromDateString: "2016_01_01")!

struct DemoView: View {
    
    @State var settingsProvider: SettingsProvider = SettingsProvider(settings: .init())
    
    @State var pastDateBeingShown: Date? = nil
    @State var showingSettings = false

    init() { }
    
    var body: some View {
        NavigationView {
            List {
                settingsSection
                healthDetailsSection
            }
            .navigationTitle("Demo")
            .toolbar { toolbarContent }
        }
        .sheet(item: $pastDateBeingShown) { healthDetailsForm(for: $0) }
        .sheet(isPresented: $showingSettings) { settingsForm }
        .onAppear(perform: appeared)
    }
    
    func appeared() {
        Task {
            let settings = await fetchSettingsFromDocuments()
            await MainActor.run {
                self.settingsProvider.settings = settings
            }

            try await HealthStore.requestPermissions()
            try await HealthProvider.syncWithHealthKitAndRecalculateAllDays()
        }
    }
    
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Clear Data") {
                    deleteAllFilesInDocuments()

                    Task {
                        var settings = await fetchSettingsFromDocuments()
                        settings.setHealthKitSyncing(for: .weight, to: true)
                        settings.setHealthKitSyncing(for: .height, to: true)
                        settings.setHealthKitSyncing(for: .leanBodyMass, to: true)
                        settings.setHealthKitSyncing(for: .fatPercentage, to: true)
                        await saveSettingsInDocuments(settings)

                        await MainActor.run { [settings] in
                            self.settingsProvider.settings = settings
                        }

                        let start = CFAbsoluteTimeGetCurrent()
                        let _ = await fetchAllDaysFromDocuments(
                            from: LogStartDate,
                            createIfNotExisting: true
                        )
                        print("Created all days in: \(CFAbsoluteTimeGetCurrent()-start)s")
                        try await HealthProvider.syncWithHealthKitAndRecalculateAllDays()
                    }
                }
                Button("Reset Current") {
                    setCurrentHealthDetails()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
    
    func setCurrentHealthDetails() {
        deleteAllFilesInDocuments()
        Task {
            var healthDetails = await fetchOrCreateHealthDetailsFromDocuments(Date.now)
            healthDetails.dateOfBirth = Date(fromDateString: "1987_06_04")!
            healthDetails.biologicalSex = .male
            healthDetails.weight = .init(
                weightInKg: 96.2,
    //            dailyValueType: .average,
                measurements: [.init(date: Date.now, weightInKg: 96.2)],
                deletedHealthKitMeasurements: []
            )
    //        healthDetails.height = .init(
    //            heightInCm: 177,
    //            measurements: [.init(date: Date.now, heightInCm: 177)],
    //            deletedHealthKitMeasurements: [],
    //            isSynced: false
    //        )
            healthDetails.leanBodyMass = .init(
                leanBodyMassInKg: 75.2,
//                fatPercentage: 21.8,
    //            dailyValueType: .average,
                measurements: [.init(
                    date: Date.now,
                    leanBodyMassInKg: 75.2,
//                    fatPercentage: 21.8,
                    source: .userEntered
                )],
                deletedHealthKitMeasurements: []
            )
            try await saveHealthDetailsInDocuments(healthDetails)
        }
    }
    
//    @ViewBuilder
    var settingsForm: some View {
//        if let settingsProvider {
            SettingsForm(settingsProvider, isPresented: $showingSettings)
//        }
    }
    
//    @ViewBuilder
    func healthDetailsForm(for date: Date) -> some View {
//        if let settingsProvider {
            MockHealthDetailsForm(
                date: date,
                settingsProvider: settingsProvider,
                isPresented: Binding<Bool>(
                    get: { true },
                    set: { if !$0 { pastDateBeingShown = nil } }
                )
            )
//        }
    }
    
    var healthDetailsSection: some View {
        
        let numberOfDays = Date.now.numberOfDaysFrom(LogStartDate)
        
        func button(daysAgo: Int) -> some View {
            let date = Date.now.moveDayBy(-daysAgo)
            return Button {
                pastDateBeingShown = date
            } label: {
                Text(date.shortDateString + "\(daysAgo == 0 ? " (Current)" : "")")
            }
        }
        
        return Section("Health Details") {
            ForEach(0...numberOfDays, id: \.self) {
                button(daysAgo: $0)
            }
        }
    }
    
    var settingsSection: some View {
        Section {
            Button {
                showingSettings = true
            } label: {
                Text("Settings")
            }
        }
    }
}

#Preview("DemoView") {
    DemoView()
}

let MockPastDate = Date.now.moveDayBy(-3)

extension Date: Identifiable {
    public var id: Date { return self }
}
