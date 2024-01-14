import SwiftUI

public var isPreview: Bool {
    return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

var CurrentHealthDetails: HealthDetails {
    fetchOrCreateHealthDetailsFromDocuments(Date.now)
}

func latestHealthDetails(to date: Date = Date.now) -> HealthProvider.LatestHealthDetails {
    let start = CFAbsoluteTimeGetCurrent()
    var latest = HealthProvider.LatestHealthDetails()
    
    let numberOfDays = Date.now.numberOfDaysFrom(DaysStartDate)
    var retrievedDetails: [HealthDetail] = []
    for i in 1...numberOfDays {
        let date = Date.now.moveDayBy(-i)
        guard let healthDetails = fetchHealthDetailsFromDocuments(date) else {
            continue
        }

        if healthDetails.hasSet(.weight) {
            latest.weight = .init(date: date, weight: healthDetails.weight)
            retrievedDetails.append(.weight)
        }

        if healthDetails.hasSet(.height) {
            latest.height = .init(date: date, height: healthDetails.height)
            retrievedDetails.append(.height)
        }

        if healthDetails.hasSet(.leanBodyMass) {
            latest.leanBodyMass = .init(date: date, leanBodyMass: healthDetails.leanBodyMass)
            retrievedDetails.append(.leanBodyMass)
        }
        
        if healthDetails.hasSet(.preganancyStatus) {
            latest.pregnancyStatus = .init(date: date, pregnancyStatus: healthDetails.pregnancyStatus)
        }
        
        if healthDetails.hasSet(.maintenance) {
            latest.maintenance = .init(date: date, maintenance: healthDetails.maintenance)
        }

        /// Once we get all (temporal) HealthDetails, stop searching
        if retrievedDetails.containsAllTemporalCases {
            break
        }
    }
    
    print("Getting latestHealthDetails for \(numberOfDays) numberOfDays took: \(CFAbsoluteTimeGetCurrent()-start)s")
    return latest
}

extension HealthProvider {
    //TODO: To be replaced in Prep with a function that asks backend for the earliest Days that contain age, sex, or smokingStatus to be as optimized as possible
    func bringForwardNonTemporalHealthDetails() async {
        guard !healthDetails.missingNonTemporalHealthDetails.isEmpty else { return }
        let start = CFAbsoluteTimeGetCurrent()
        
        let numberOfDays = healthDetails.date.numberOfDaysFrom(LogStartDate)
        for i in 0...numberOfDays {
            let date = healthDetails.date.moveDayBy(-i)
            guard let pastHealthDetails = fetchHealthDetailsFromDocuments(date) else {
                continue
            }

            if !healthDetails.hasSet(.age), let dateOfBirthComponents = pastHealthDetails.dateOfBirthComponents {
                healthDetails.dateOfBirthComponents = dateOfBirthComponents
            }
            
            if !healthDetails.hasSet(.sex), pastHealthDetails.hasSet(.sex) {
                healthDetails.biologicalSex = pastHealthDetails.biologicalSex
            }
            
            if !healthDetails.hasSet(.smokingStatus), pastHealthDetails.hasSet(.smokingStatus) {
                healthDetails.smokingStatus = pastHealthDetails.smokingStatus
            }

            /// Once we get all non-temporal HealthDetails, stop searching early
            if healthDetails.missingNonTemporalHealthDetails.isEmpty {
                break
            }
        }
        
        print("bringForwardNonTemporalHealthDetails() for \(numberOfDays) numberOfDays took: \(CFAbsoluteTimeGetCurrent()-start)s")
    }
}

struct MockHealthDetailsForm: View {
    
    @Bindable var settingsProvider: SettingsProvider

    @State var healthProvider: HealthProvider
    @Binding var isPresented: Bool
    
    let date: Date
    
    init(
        date: Date,
        settingsProvider: SettingsProvider,
        isPresented: Binding<Bool> = .constant(true)
    ) {
        self.date = date
        self.settingsProvider = settingsProvider
        _isPresented = isPresented
        
        let healthDetails = fetchOrCreateHealthDetailsFromDocuments(date)
        let healthProvider = HealthProvider(
            healthDetails: healthDetails,
            settingsProvider: settingsProvider
        )
        _healthProvider = State(initialValue: healthProvider)
    }

    var body: some View {
        HealthDetailsForm(
            healthProvider: healthProvider,
            isPresented: $isPresented
        )
    }
}


let MockCurrentProvider = HealthProvider(
    healthDetails: HealthDetails(
        date: Date.now,
        biologicalSex: .notSet,
        smokingStatus: .smoker
    ),
    settingsProvider: SettingsProvider()
)

let MockPastProvider = HealthProvider(
    healthDetails: HealthDetails(
        date: Date.now.moveDayBy(-1),
        biologicalSex: .male,
        dateOfBirthComponents: 20.dateOfBirthComponents,
        smokingStatus: .nonSmoker,
        pregnancyStatus: .notSet
    ),
    settingsProvider: SettingsProvider()
)

//MARK: Reusable

func deleteAllFilesInDocuments() {
    do {
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: getDocumentsDirectory(),
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )
        for fileURL in fileURLs {
            try FileManager.default.removeItem(at: fileURL)
        }
    } catch  {
        print(error)
    }
}

func getDocumentsDirectory() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}

struct Day: Codable, Hashable {
    let date: Date
    var healthDetails: HealthDetails
    var dietaryEnergyPoint: DietaryEnergyPoint?
    var energyInKcal: Double?
    
    init(date: Date) {
        self.date = date
        self.healthDetails = HealthDetails(date: date)
    }
}

func fetchOrCreateDayFromDocuments(_ date: Date) -> Day {
    let filename = "\(date.dateString).json"
    let url = getDocumentsDirectory().appendingPathComponent(filename)
    do {
        let data = try Data(contentsOf: url)
        let day = try JSONDecoder().decode(Day.self, from: data)
        return day
    } catch {
        let day = Day(date: date)
        saveDayInDocuments(day)
        return day
    }
}

func fetchAllDaysFromDocuments() async -> [Day] {
    //TODO: In production:
    /// [ ] Optimizing by not fetching the meals etc, only fetching fields we need
    var days: [Day] = []
    for i in (0...Date.now.numberOfDaysFrom(LogStartDate)).reversed() {
        let date = Date.now.moveDayBy(-i)
        days.append(fetchOrCreateDayFromDocuments(date))
    }
    return days
}

func fetchDayFromDocuments(_ date: Date) -> Day? {
    let filename = "\(date.dateString).json"
    let url = getDocumentsDirectory().appendingPathComponent(filename)
    do {
        let data = try Data(contentsOf: url)
        let day = try JSONDecoder().decode(Day.self, from: data)
        return day
    } catch {
        return nil
    }
}

func saveDayInDocuments(_ day: Day) {
    do {
        let filename = "\(day.date.dateString).json"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        let json = try JSONEncoder().encode(day)
        try json.write(to: url)
    } catch {
        fatalError()
    }
}

func fetchOrCreateHealthDetailsFromDocuments(_ date: Date) -> HealthDetails {
    fetchOrCreateDayFromDocuments(date).healthDetails
}

func fetchHealthDetailsFromDocuments(_ date: Date) -> HealthDetails? {
    fetchDayFromDocuments(date)?.healthDetails
}

func saveHealthDetailsInDocuments(_ healthDetails: HealthDetails) {
    var day = fetchOrCreateDayFromDocuments(healthDetails.date)
    day.healthDetails = healthDetails
    saveDayInDocuments(day)
//    do {
//        let filename = "\(healthDetails.date.dateString).json"
//        let url = getDocumentsDirectory().appendingPathComponent(filename)
//        let json = try JSONEncoder().encode(healthDetails)
//        try json.write(to: url)
//    } catch {
//        fatalError()
//    }
}

func fetchSettingsFromDocuments() -> Settings {
    let filename = "settings.json"
    let url = getDocumentsDirectory().appendingPathComponent(filename)
    do {
        let data = try Data(contentsOf: url)
        let settings = try JSONDecoder().decode(Settings.self, from: data)
        return settings
    } catch {
        let settings = Settings()
        saveSettingsInDocuments(settings)
        return settings
    }
}

func saveSettingsInDocuments(_ settings: Settings) {
    do {
        let filename = "settings.json"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        let json = try JSONEncoder().encode(settings)
        try json.write(to: url)
    } catch {
        fatalError()
    }
}
