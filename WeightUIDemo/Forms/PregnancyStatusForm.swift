import SwiftUI
import SwiftSugar

struct PregnancyStatusForm: View {

    @Binding var isPresented: Bool
    let date: Date
    @State var pregnancyStatus: PregnancyStatus = .notSet
    let saveHandler: (PregnancyStatus) -> ()

    init(
        date: Date,
        pregnancyStatus: PregnancyStatus,
        isPresented: Binding<Bool> = .constant(true),
        save: @escaping (PregnancyStatus) -> ()
    ) {
        self.date = date
        self.saveHandler = save
        _isPresented = isPresented
        _pregnancyStatus = State(initialValue: pregnancyStatus)
    }
    
    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            pregnancyStatus: healthProvider.healthDetails.pregnancyStatus,
            isPresented: isPresented,
            save: healthProvider.savePregnancyStatus
        )
    }

    var body: some View {
        Form {
            dateSection
            picker
            explanation
        }
        .navigationTitle("Pregnancy Status")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) { bottomValue }
    }
    
    var dateSection: some View {
        Section {
            HStack {
                Text("Date")
                Spacer()
                Text(date.shortDateString)
            }
        }
    }
    var picker: some View {
        let binding = Binding<PregnancyStatus>(
            get: { pregnancyStatus },
            set: { newValue in
                self.pregnancyStatus = newValue
                handleChanges()
            }
        )
        return PickerSection(
            [PregnancyStatus.notPregnantOrLactating, PregnancyStatus.pregnant, PregnancyStatus.lactating],
            binding
        )
        
    }
    var bottomValue: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Spacer()
            Text(pregnancyStatus.name)
                .font(NotSetFont)
                .foregroundStyle(pregnancyStatus == .notSet ? .secondary : .primary)
        }
        .padding(.horizontal, BottomValueHorizontalPadding)
        .padding(.vertical, BottomValueVerticalPadding)
        .background(.bar)
    }

    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isPresented = false
            } label: {
                CloseButtonLabel()
            }
        }
    }

    func handleChanges() {
        save()
    }
    
    func save() {
        saveHandler(pregnancyStatus)
    }

    var explanation: some View {
        var header: some View {
            Text("Usage")
                .formTitleStyle()
        }

        return Section(header: header) {
            Text("Your pregnancy status may be used when picking daily values for micronutrients.\n\nFor example, the recommended daily allowance for Iodine almost doubles when a mother is breastfeeding.")
        }
    }

}
