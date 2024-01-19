import Foundation

let DaysStartDateKey = "DaysStartDate"

extension DayProvider {
    //TODO: Make sure that the start date gets the first date that actually has food logged in it so that we don't get a Day we may have created to house something like a legacy height measurement.
    static func fetchBackendLogStartDate() async -> Date {
        LogStartDate
    }

    static func fetchBackendDaysStartDate() async -> Date? {
        guard let string = UserDefaults.standard.string(forKey: DaysStartDateKey) else {
            return nil
        }
        return Date(fromDateString: string)
    }
    
    static func updateDaysStartDate(_ date: Date) async {
        UserDefaults.standard.setValue(date.dateString, forKey: DaysStartDateKey)
    }
    
    static func fetchBackendEnergyInKcal(for date: Date) async -> Double? {
        let day = await fetchOrCreateDayFromDocuments(date)
        return day.energyInKcal
    }
    
    static func fetchPrelogDeletedHealthKitUUIDs() async -> [UUID] {
        let days = await fetchAllPreLogDaysFromDocuments()
        return days.map { $1.healthDetails.deletedHealthKitUUIDs }.flatMap { $0 }
    }
}
