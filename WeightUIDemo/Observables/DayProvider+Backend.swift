import Foundation

extension DayProvider {
    //TODO: Make sure that the start date gets the first date that actually has food logged in it so that we don't get a Day we may have created to house something like a legacy height measurement.
    static func fetchBackendLogStartDate() async -> Date {
        LogStartDate
    }

    static func fetchBackendDaysStartDate() async -> Date {
        DaysStartDate
    }
    
    static func fetchBackendEnergyInKcal(for date: Date) async -> Double? {
        let day = await fetchOrCreateDayFromDocuments(date)
        return day.energyInKcal
    }
}
