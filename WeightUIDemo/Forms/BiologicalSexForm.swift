import SwiftUI
import SwiftSugar

struct BiologicalSexForm: View {
    
    @Binding var isPresented: Bool
    let date: Date
    @State var biologicalSex: BiologicalSex
    let saveHandler: (BiologicalSex) -> ()

    init(
        date: Date,
        biologicalSex: BiologicalSex,
        isPresented: Binding<Bool> = .constant(true),
        save: @escaping (BiologicalSex) -> ()
    ) {
        self.date = date
        _isPresented = isPresented
        
        _biologicalSex = State(initialValue: biologicalSex)
        self.saveHandler = save
    }

    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool> = .constant(true)
    ) {
        self.init(
            date: healthProvider.healthDetails.date,
            biologicalSex: healthProvider.healthDetails.biologicalSex,
            isPresented: isPresented,
            save: healthProvider.saveBiologicalSex
        )
    }
    
    var body: some View {
        Form {
//            dateSection
            picker
            explanation
        }
        .navigationTitle("Biological Sex")
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

    var bottomValue: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Spacer()
            ZStack {
                
                /// dummy text placed to ensure height stays consistent
                Text("0")
                    .font(LargeNumberFont)
                    .opacity(0)

                Text(biologicalSex != .notSet ? biologicalSex.name : NotSetString)
                    .font(LargeUnitFont)
//                    .font(sex == .other ? LargeUnitFont : LargeNumberFont)
                    .foregroundStyle(biologicalSex != .notSet ? .primary : .secondary)
            }
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
    
    var explanation: some View {
        var header: some View {
            Text("Usage")
                .formTitleStyle()
        }

        return Section(header: header) {
            VStack(alignment: .leading) {
                Text("Your biological sex is used when:")
                dotPoint("Calculating your Resting Energy or Lean Body Mass.")
                dotPoint("Assigning nutrient Recommended Daily Allowances.")
            }
        }
    }

    var picker: some View {
        let binding = Binding<BiologicalSex>(
            get: { biologicalSex },
            set: { newValue in
                self.biologicalSex = newValue
                handleChanges()
            }
        )
        return PickerSection(
            [BiologicalSex.female, BiologicalSex.male],
            binding
        )
    }
    
    func handleChanges() {
        save()
    }
    
    func save() {
        saveHandler(biologicalSex)
    }
}

#Preview("DemoView") {
    DemoView()
}
