import Foundation

extension HealthDetails {
    mutating func recalculateDailyValues(using settings: Settings) {
        height.setDailyValue(for: settings.dailyValueType(for: .height))
        weight.setDailyValue(for: settings.dailyValueType(for: .weight))
        leanBodyMass.setDailyValue(for: settings.dailyValueType(for: .leanBodyMass))
        fatPercentage.setDailyValue(for: settings.dailyValueType(for: .fatPercentage))
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
                isConvertedFromFatPercentage: true
            )
        }
        leanBodyMass.measurements.append(contentsOf: convertedMeasurements)
    }
}
