import SwiftUI
import PrepShared

struct DietaryEnergyCell: View {
    
    let point: DietaryEnergyPoint
    let energyUnit: EnergyUnit
    
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
            guard point.source != .notCounted else {
                return DietaryEnergyPointSource.notCounted.name
            }
            guard let kcal = point.kcal else {
                return NotSetString
            }
            let value = EnergyUnit.kcal.convert(kcal, to: energyUnit)
            return "\(value.formattedEnergy) \(energyUnit.abbreviation)"
        }
        
        var foregroundColor: Color {
            point.source == .notCounted || point.kcal == nil
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
