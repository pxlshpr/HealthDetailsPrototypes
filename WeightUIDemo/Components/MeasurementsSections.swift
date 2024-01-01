import SwiftUI
import PrepShared

struct MeasurementsSections<U:HealthUnit>: View {
    
    @Environment(SettingsProvider.self) var settingsProvider

    @Binding var measurements: [any Measurable]
    @Binding var deletedHealthKitMeasurements: [any Measurable]
    @Binding var showingForm: Bool
    @Binding var isPast: Bool
    @Binding var isEditing: Bool

    let handleChanges: () -> ()
    
    var body: some View {
        Group {
            measurementsSection
            deletedHealthDataSection
        }
    }
    
    var measurementsSection: some View {
        Section(footer: footer) {
            cells
            lastRow
        }
    }
    
    var deletedHealthDataSection: some View {
        var header: some View {
            Text("Excluded Health Data")
        }
        
        func restore(_ measurement: any Measurable) {
            withAnimation {
                measurements.append(measurement)
                measurements.sort(by: { $0.date < $1.date })
                deletedHealthKitMeasurements.removeAll(where: { $0.id == measurement.id })
            }
            handleChanges()
        }
        
        return Group {
            if !deletedHealthKitMeasurements.isEmpty {
                Section(header: header) {
                    ForEach(deletedHealthKitMeasurements, id: \.id) { data in
                        HStack {
                            cell(for: data, disabled: true)
                            Button {
                                restore(data)
                            } label: {
                                Image(systemName: "arrow.up.bin")
                            }
                        }
                    }
                }
            }
        }
    }
    @ViewBuilder
    var footer: some View {
        if !measurements.isEmpty {
            Text(DailyValueType.last.description)
        }
    }
    
    var isDisabled: Bool {
        isPast && !isEditing
    }

    var lastRow: some View {
        var shouldShow: Bool {
            !(isDisabled && !measurements.isEmpty)
        }
        
        var content: some View {
            HStack {
                if isDisabled {
                    if measurements.isEmpty {
                        Text("No Measurements")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Add Measurement")
                        .foregroundStyle(Color.accentColor)
                }
                Spacer()
                Button {
                    showingForm = true
                } label: {
                }
                .disabled(isDisabled)
            }
        }
        
        return Group {
            if shouldShow {
                content
            }
        }
    }
    
    var cells: some View {
        ForEach(measurements, id: \.id) { measurement in
            cell(for: measurement)
                .deleteDisabled(isPast)
        }
        .onDelete(perform: delete)
    }
    
    func delete(at offsets: IndexSet) {
        let dataToDelete = offsets.map { self.measurements[$0] }
        withAnimation {
            for data in dataToDelete {
                delete(data)
            }
        }
    }
    
    func delete(_ data: any Measurable) {
        if data.isFromHealthKit {
            deletedHealthKitMeasurements.append(data)
            deletedHealthKitMeasurements.sort { $0.date < $1.date }
        }
        measurements.removeAll(where: { $0.id == data.id })
        handleChanges()
    }

    var unit: U {
        settingsProvider.unit(for: U.self) as! U
    }

    func cell(for measurement: any Measurable, disabled: Bool = false) -> some View {

        var double: Double {
            let double = U.default.doubleComponent(measurement.value, in: unit)
            print("double is: \(double)")
            return double
        }

        var int: Int? {
            let int = U.default.intComponent(measurement.value, in: unit)
            print("Converting \(measurement.value) from \(U.default) to \(unit)")
            print("int is: \(int)")
            return int
        }
        
        return MeasurementCell(
            imageType: measurement.imageType,
            timeString: measurement.timeString,
            isDisabled: disabled,
            showDeleteButton: Binding<Bool>(
                get: { isEditing && isPast },
                set: { _ in }
            ),
            deleteAction: {
                withAnimation {
                    delete(measurement)
                }
            },
            double: double,
            int: int,
            doubleUnitString: doubleUnitString,
            intUnitString: intUnitString
        )
    }
    
    var intUnitString: String? {
        unit.intUnitString
    }
    
    var doubleUnitString: String {
        unit.doubleUnitString
    }
}
