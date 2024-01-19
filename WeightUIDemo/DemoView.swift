import SwiftUI
import SwiftSugar

let LargeNumberFont: Font = .system(.largeTitle, design: .rounded, weight: .bold)
//let LogStartDate = Date(fromDateString: "2023_12_01")!
//let DaysStartDate = Date(fromDateString: "2016_01_01")!

let LogStartDate = Date(fromDateString: "2022_01_01")!
//let LogStartDate = Date.now.startOfDay

struct DemoView: View {
    
    @State var settingsProvider: SettingsProvider = SettingsProvider(settings: .init())
    
    @State var pastDateBeingShown: Date? = nil
    @State var showingSettings = false

    @AppStorage("initialLaunchCompleted") var initialLaunchCompleted: Bool = false
    
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
            
            if initialLaunchCompleted  {
                try await HealthStore.requestPermissions()
                try await HealthProvider.syncWithHealthKitAndRecalculateAllDays()
            } else {
                resetData()
            }
            
            if let daysStartDate = await DayProvider.fetchBackendDaysStartDate() {
                var preLogDates: [Date] = []
                /// For each date from DaysStartDate till the day before LogStartDate, check if we have a Day for it, and if so append the date
                let numberOfDays = LogStartDate.numberOfDaysFrom(daysStartDate)
                for i in 0..<numberOfDays {
                    let date = daysStartDate.moveDayBy(i)
                    if let _ = await fetchDayFromDocuments(date) {
                        preLogDates.append(date)
                    }
                }
                await MainActor.run { [preLogDates] in
                    self.preLogDates = preLogDates
                }
            }
        }
    }
    
    func resetData() {
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

            initialLaunchCompleted = true
        }
    }
    
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button("Reset Data") {
                    resetData()
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
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
        
        return Section("Health Details") {
            ForEach(0...numberOfDays, id: \.self) {
                button(Date.now.moveDayBy(-$0))
            }
        }
    }
    
    func button(_ date: Date) -> some View {
        return Button {
            pastDateBeingShown = date
        } label: {
            Text(date.shortDateString + "\(date.isToday ? " (Current)" : "")")
        }
    }
    
    @State var preLogDates: [Date] = []
    
    var preLogHealthDetailsSection: some View {
        Section("Pre-Log Health Details") {
            ForEach(preLogDates, id: \.self) {
                button($0)
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
