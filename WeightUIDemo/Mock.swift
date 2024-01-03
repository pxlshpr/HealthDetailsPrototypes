import SwiftUI

var CurrentHealthDetails: HealthDetails {
    fetchHealthDetailsFromDocuments(Date.now)
}

extension Array where Element == HealthDetail {
    var containsAllCases: Bool {
        HealthDetail.allCases.allSatisfy { contains($0) }
    }
}

func latestHealthDetails(to date: Date = Date.now) -> HealthProvider.LatestHealthDetails {
    let start = CFAbsoluteTimeGetCurrent()
    print("-- starting latestHealthDetails")
    var latest = HealthProvider.LatestHealthDetails()
    
    let numberOfDays = Date.now.numberOfDaysFrom(PreviousMockDate)
    var setDetails: [HealthDetail] = []
    for i in 0...numberOfDays {
        let date = Date.now.moveDayBy(-i)
        print("-- fetching for \(date)")
        let healthDetails = fetchHealthDetailsFromDocuments(date)
        print("-- healthDetails.weight.weightInKg: \(healthDetails.weight.weightInKg)")

        if healthDetails.hasSet(.weight) {
            latest.weight = .init(date: date, weight: healthDetails.weight)
            setDetails.append(.weight)
        }

        if healthDetails.hasSet(.height) {
            latest.height = .init(date: date, height: healthDetails.height)
            setDetails.append(.height)
        }

        if healthDetails.hasSet(.leanBodyMass) {
            latest.leanBodyMass = .init(date: date, leanBodyMass: healthDetails.leanBodyMass)
            setDetails.append(.leanBodyMass)
        }

        /// Once we get all HealthDetails, stop searching
        if setDetails.containsAllCases {
            break
        }
    }
    
    print("** latestHealthDetails took: \(CFAbsoluteTimeGetCurrent()-start)s")
    return latest
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
        print("Latest HealthDetails for \(date.shortDateString):")
        print(latest)
        
        let healthProvider = HealthProvider(
            isCurrent: date.isToday,
            healthDetails: healthDetails,
            latest: latest
        )
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
