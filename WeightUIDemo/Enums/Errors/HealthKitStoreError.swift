import Foundation

public enum HealthStoreError: Error {
    case healthKitNotAvailable
    case permissionsError(Error)
}
