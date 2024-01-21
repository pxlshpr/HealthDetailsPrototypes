import Foundation

extension HealthDetails {
    mutating func recalculateDailyMeasurements(using settings: Settings) {
        height.setDailyMeasurement(for: settings.dailyMeasurementType(for: .height))
        weight.setDailyMeasurement(for: settings.dailyMeasurementType(for: .weight))
        leanBodyMass.setDailyMeasurement(for: settings.dailyMeasurementType(for: .leanBodyMass))
        fatPercentage.setDailyMeasurement(for: settings.dailyMeasurementType(for: .fatPercentage))
    }
    
    mutating func convertLeanBodyMassesToFatPercentages() {
        /// Remove all the previous converted fat percentages
        fatPercentage.measurements.removeAll(where: { $0.isConvertedFromLeanBodyMass })

        /// See if we sitll have a weight available before continuing
        guard let currentOrLatestWeightInKg else { return }
        
        /// Now convert the measurements and add them
        let convertedMeasurements: [FatPercentageMeasurement] = leanBodyMass
            .measurements
            .nonConverted
            .compactMap
        { measurement in

            /// Detect already converted values by checking if its HealthKit, and if so seeing if there is a counterpart at the same minute as this value that’s also HealthKit
            if measurement.isHealthKitCounterpartToAMeasurement(in: fatPercentage) {
                return nil
            }

            return FatPercentageMeasurement(
                date: measurement.date,
                percent: calculateFatPercentage(
                    leanBodyMassInKg: measurement.leanBodyMassInKg,
                    weightInKg: currentOrLatestWeightInKg
                ),
                source: measurement.source,
                healthKitUUID: measurement.healthKitUUID,
                isConvertedFromLeanBodyMass: true
            )
        }
        fatPercentage.measurements.append(contentsOf: convertedMeasurements)
    }
    
    mutating func convertFatPercentagesToLeanBodyMasses() {
        /// Remove all the previous converted lean body masses
        leanBodyMass.measurements.removeAll(where: { $0.isConvertedFromFatPercentage })

        /// See if we sitll have a weight available before continuing
        guard let currentOrLatestWeightInKg else { return }
        
        /// Now convert the measurements and add them
        let convertedMeasurements: [LeanBodyMassMeasurement] = fatPercentage
            .measurements
            .nonConverted
            .compactMap
        { measurement in

            /// Detect already converted values by checking if its HealthKit, and if so seeing if there is a counterpart at the same minute as this value that’s also HealthKit
            if measurement.isHealthKitCounterpartToAMeasurement(in: leanBodyMass) {
                return nil
            }

            return LeanBodyMassMeasurement(
                date: measurement.date,
                leanBodyMassInKg: calculateLeanBodyMass(
                    fatPercentage: measurement.percent,
                    weightInKg: currentOrLatestWeightInKg),
                source: measurement.source,
                healthKitUUID: measurement.healthKitUUID,
                isConvertedFromFatPercentage: true
            )
        }
        leanBodyMass.measurements.append(contentsOf: convertedMeasurements)
    }
}

extension HealthDetails {
    mutating func unsetPregnancyAndSmokingStatusIfNeeded() {
        if biologicalSex == .male {
            pregnancyStatus = .notSet
        }
        if pregnancyStatus.isPregnantOrLactating, smokingStatus == .smoker {
            smokingStatus = .nonSmoker
        }
    }
}

extension PregnancyStatus {
    var isPregnantOrLactating: Bool {
        self == .pregnant || self == .lactating
    }
}
