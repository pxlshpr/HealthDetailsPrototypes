import SwiftUI
import PrepShared

struct MeasurementCell<U : HealthUnit>: View {

    let measurement: any Measurable
    @Bindable var settingsProvider: SettingsProvider
    let isDisabled: Bool
    @Binding var showDeleteButton: Bool
    let deleteAction: () -> ()

    init(
        measurement: any Measurable,
        settingsProvider: SettingsProvider,
        isDisabled: Bool,
        showDeleteButton: Binding<Bool> = .constant(false),
        deleteAction: @escaping () -> Void
    ) {
        self.measurement = measurement
        self.settingsProvider = settingsProvider
        self.isDisabled = isDisabled
        _showDeleteButton = showDeleteButton
        self.deleteAction = deleteAction
    }
    
    var body: some View {
        HStack {
            deleteButton
//                .opacity(isDisabled ? 0.6 : 1)
            image
            timeText
            Spacer()
            secondaryValueText
            valueText
        }
    }
    
    @ViewBuilder
    var secondaryValueText: some View {
        if let string = measurement.secondaryValueString {
            Text(string)
                .foregroundStyle(isDisabled ? .tertiary : .secondary)
        }
    }
    
    var timeText: some View {
        Text(measurement.timeString)
            .foregroundStyle(textColor)
    }
    
    var valueText: some View {
        Text(valueString)
            .foregroundStyle(textColor)
    }
    
    var textColor: Color {
        isDisabled ? .secondary : .primary
    }
    
    @ViewBuilder
    var image: some View {
        switch measurement.imageType {
        case .healthKit:
            Image("AppleHealthIcon")
                .resizable()
                .frame(width: 24, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(.systemGray3), lineWidth: 0.5)
                )
        case .systemImage(let imageName, let scale):
            Image(systemName: imageName)
                .scaleEffect(scale)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(Color(.systemGray4))
                )
        }
    }
    
    @ViewBuilder
    var deleteButton: some View {
        if showDeleteButton {
            Button {
                deleteAction()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .imageScale(.large)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
    
    //MARK: - Computed
    
    var valueString: String {
        let double = "\(double.cleanHealth) \(doubleUnitString)"
        return if let int, let intUnitString {
            "\(int) \(intUnitString) \(double)"
        } else {
            double
        }
    }

    var double: Double {
        U.default.doubleComponent(measurement.value, in: unit)
    }

    var int: Int? {
        U.default.intComponent(measurement.value, in: unit)
    }

    var unit: U {
        settingsProvider.unit(for: U.self) as! U
    }

    var intUnitString: String? {
        unit.intUnitString
    }
    
    var doubleUnitString: String {
        unit.doubleUnitString
    }
}
