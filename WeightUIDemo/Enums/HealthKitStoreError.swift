import Foundation

public enum HealthStoreError: Error {
    case healthKitNotAvailable
    case permissionsError(Error)
    case couldNotGetSample
    case couldNotGetStatistics
    case dateCreationError
    
    case noData
    case noDataOrNotAuthorized
}
