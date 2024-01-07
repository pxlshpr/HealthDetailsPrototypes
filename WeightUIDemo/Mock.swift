import SwiftUI

public var isPreview: Bool {
    return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

var CurrentHealthDetails: HealthDetails {
    fetchHealthDetailsFromDocuments(Date.now)
}

func latestHealthDetails(to date: Date = Date.now) -> HealthProvider.LatestHealthDetails {
    let start = CFAbsoluteTimeGetCurrent()
    print("-- starting latestHealthDetails")
    var latest = HealthProvider.LatestHealthDetails()
    
    let numberOfDays = Date.now.numberOfDaysFrom(PreviousMockDate)
    var retrievedDetails: [HealthDetail] = []
    for i in 1...numberOfDays {
        let date = Date.now.moveDayBy(-i)
        let healthDetails = fetchHealthDetailsFromDocuments(date)

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
    
    print("** latestHealthDetails took: \(CFAbsoluteTimeGetCurrent()-start)s")
    return latest
}

extension HealthProvider {
    //TODO: To be replaced in Prep with a function that asks backend for the earliest Days that contain age, sex, or smokingStatus
    func bringForwardNonTemporalHealthDetails() {
        guard !healthDetails.missingNonTemporalHealthDetails.isEmpty else { return }
        let start = CFAbsoluteTimeGetCurrent()
        print("-- starting bringForwardNonTemporalHealthDetails")
        
        let numberOfDays = healthDetails.date.numberOfDaysFrom(PreviousMockDate)
        for i in 0...numberOfDays {
            let date = healthDetails.date.moveDayBy(-i)
            let pastHealthDetails = fetchHealthDetailsFromDocuments(date)

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
        
        print("** bringForwardNonTemporalHealthDetails took: \(CFAbsoluteTimeGetCurrent()-start)s")
    }
}

struct MockHealthDetailsForm: View {
    
    @Environment(SettingsProvider.self) var settingsProvider

    @State var healthProvider: HealthProvider
    @Binding var isPresented: Bool
    
    init(
        date: Date,
        isPresented: Binding<Bool> = .constant(true)
    ) {
        _isPresented = isPresented
        
        let healthDetails = fetchHealthDetailsFromDocuments(date)

        let latest = latestHealthDetails(to: date)
        
        let healthProvider = HealthProvider(
            isCurrent: date.isToday,
            healthDetails: healthDetails,
            latest: latest
        )
        
        /// Get HealthProvider to bring forward any non-temporal HealthDetails (age, sex, smokingStatus)
        healthProvider.bringForwardNonTemporalHealthDetails()
        
        _healthProvider = State(initialValue: healthProvider)
    }

    var body: some View {
        HealthDetailsForm(
            healthProvider: healthProvider,
            isPresented: $isPresented
        )
        .environment(settingsProvider)
    }
}


let MockCurrentProvider = HealthProvider(
    isCurrent: true,
    healthDetails: HealthDetails(
        date: Date.now,
        biologicalSex: .notSet
    )
)

let MockPastProvider = HealthProvider(
    isCurrent: false,
    healthDetails: HealthDetails(
        date: Date.now.moveDayBy(-1),
        biologicalSex: .male,
        dateOfBirthComponents: 20.dateOfBirthComponents,
        smokingStatus: .nonSmoker,
        pregnancyStatus: .notSet
    )
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

func fetchHealthDetailsFromDocuments(_ date: Date) -> HealthDetails {
    let filename = "\(date.dateString).json"
    let url = getDocumentsDirectory().appendingPathComponent(filename)
    do {
        let data = try Data(contentsOf: url)
        let healthDetails = try JSONDecoder().decode(HealthDetails.self, from: data)
        return healthDetails
    } catch {
        let healthDetails = HealthDetails(date: date)
        saveHealthDetailsInDocuments(healthDetails)
        return healthDetails
    }
}

func saveHealthDetailsInDocuments(_ healthDetails: HealthDetails) {
    do {
        let filename = "\(healthDetails.date.dateString).json"
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        let json = try JSONEncoder().encode(healthDetails)
        try json.write(to: url)
    } catch {
        fatalError()
    }
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
