import SwiftUI
import PrepShared

struct MeasurementsSections<U : HealthUnit>: View {
    
    @Bindable var settingsProvider: SettingsProvider
    @Binding var measurements: [any Measurable]
    @Binding var deletedHealthKitMeasurements: [any Measurable]
    @Binding var showingForm: Bool
    
    let handleChanges: () -> ()
    
    var body: some View {
        Group {
            measurementsSection
            deletedHealthDataSection
        }
    }
    
    var measurementsSection: some View {
        Section {
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
    
    var lastRow: some View {
        HStack {
            Text("Add Measurement")
                .foregroundStyle(Color.accentColor)
            Spacer()
            Button {
                showingForm = true
            } label: {
            }
        }
    }
    
    var cells: some View {
        ForEach(measurements, id: \.id) { measurement in
            cell(for: measurement)
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

    func cell(for measurement: any Measurable, disabled: Bool = false) -> some View {
        MeasurementCell<U>(
            measurement: measurement,
            settingsProvider: settingsProvider,
            isDisabled: disabled,
            deleteAction: {
                withAnimation {
                    delete(measurement)
                }
            }
        )
    }
}
