import SwiftUI
import PrepShared
struct DietaryEnergyCell: View {
    
    @Environment(SettingsProvider.self) var settingsProvider
    let point: DietaryEnergyPoint
    
    var body: some View {
        HStack {
            DietaryEnergyPointSourceImage(source: point.source)
            dateText
            Spacer()
            detail
        }
    }

    var detail: some View {
        var label: String {
            guard point.source != .useAverage else {
                return "Excluded"
            }
            guard let kcal = point.kcal else {
                return "Not Set"
            }
            let value = EnergyUnit.kcal.convert(kcal, to: settingsProvider.energyUnit)
            return "\(value.formattedEnergy) \(settingsProvider.energyUnit.abbreviation)"
        }
        
        var foregroundColor: Color {
            point.source == .useAverage || point.kcal == nil
            ? Color(.secondaryLabel)
            : Color(.label)
        }
        
        return Text(label)
            .foregroundStyle(foregroundColor)
    }
    
    var dateText: some View {
        Text(point.date.shortDateString)
            .foregroundStyle(Color(.label))
    }
}
