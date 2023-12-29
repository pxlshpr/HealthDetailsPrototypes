import SwiftUI
import SwiftSugar

struct AgeForm: View {
    
//    @Environment(\.dismiss) var dismiss

    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24
    
    @State var showingAgeAlert = false
    @State var showingDateOfBirthAlert = false

    @State var age: Int? = nil
    @State var ageTextAsInt: Int? = nil
    @State var ageText: String = ""
    @State var dateOfBirth = DefaultDateOfBirth
    @State var chosenDateOfBirth = DefaultDateOfBirth

    @State var isEditing: Bool
    let isPast: Bool
    
    enum Mode {
        case healthDetails
        case healthDetailsPast
        case restingEnergyVariable
        case pastRestingEnergyVariable
        case leanBodyMassVariable
        case pastLeanBodyMassVariable
    }
    
    init(isPast: Bool = false) {
        _isEditing = State(initialValue: isPast ? false : true)
        self.isPast = isPast
    }
    
    var body: some View {
        Form {
            explanation
            if !isEditing {
                notice
            } else {
                actions
            }
        }
        .navigationTitle("Age")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .alert("Enter your age", isPresented: $showingAgeAlert) {
            TextField("Enter your age", text: ageTextBinding)
                .keyboardType(.numberPad)
            Button("OK", action: submitAge)
            Button("Cancel") { }
        }
        .sheet(isPresented: $showingDateOfBirthAlert) {
            NavigationView {
                DatePicker(
                    "Date of Birth",
                    selection: $chosenDateOfBirth,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .navigationTitle("Date of Birth")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dateOfBirth = chosenDateOfBirth
                            withAnimation {
                                let age = dateOfBirth.age
                                self.age = age
                                ageText = "\(age)"
                            }
                            showingDateOfBirthAlert = false
                        }
                        .fontWeight(.semibold)
                    }
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            chosenDateOfBirth = dateOfBirth
                            showingDateOfBirthAlert = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    var notice: some View {
        NoticeSection(
            style: .plain,
            title: "Previous Data",
            message: "This data has been preserved to ensure any goals or daily values set on this day remain unchanged."
//            image: {
//                Image(systemName: "calendar.badge.clock")
//                    .font(.system(size: 30))
//                    .padding(5)
//            }
        )
    }

    var ageTextBinding: Binding<String> {
        Binding<String>(
            get: { ageText },
            set: { newValue in
                ageTextAsInt = Int(newValue)
                ageText = if let ageTextAsInt {
                    "\(ageTextAsInt)"
                } else {
                    ""
                }
            }
        )
    }
    
    func submitAge() {
        withAnimation {
            age = ageTextAsInt
            if let ageTextAsInt {
                dateOfBirth = ageTextAsInt.dateOfBirth
                chosenDateOfBirth = ageTextAsInt.dateOfBirth
            }
        }
    }

    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .bottomBar) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Spacer()
                    if let age {
                        Text("\(age)")
                            .contentTransition(.numericText(value: Double(age)))
                            .font(LargeNumberFont)
                        Text("years")
                            .font(LargeUnitFont)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Not Set")
                            .font(NotSetFont)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
//                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }

    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Your age may be used when:")
                dotPoint("Calculating your estimated resting energy.")
                dotPoint("Picking daily values for micronutrients.")
            }
        }
    }
    
    struct ListData: Hashable {
        let isHealth: Bool
        let dateString: String
        let valueString: String
        
        init(_ isHealth: Bool, _ dateString: String, _ valueString: String) {
            self.isHealth = isHealth
            self.dateString = dateString
            self.valueString = valueString
        }
    }
    
    let listData: [ListData] = [
        .init(false, "9:42 am", "93.7 kg"),
        .init(true, "12:07 pm", "94.6 kg"),
        .init(false, "5:35 pm", "92.5 kg"),
    ]
    
    func cell(for listData: ListData) -> some View {
        HStack {
            if listData.isHealth {
                Image("AppleHealthIcon")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(.systemGray3), lineWidth: 0.5)
                    )
            } else {
                Image(systemName: "pencil")
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundStyle(Color(.systemGray4))
                    )
            }
            Text(listData.dateString)
            
            Spacer()
            Text(listData.valueString)
        }
    }
        
    var actions: some View {
        Group {
            Section {
                Button {
                    
                } label: {
                    HStack {
                        Text("Read from Apple Health")
                        Spacer()
                        Image("AppleHealthIcon")
                            .resizable()
                            .frame(width: imageScale * scale, height: imageScale * scale)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color(.systemGray3), lineWidth: 0.5)
                            )
                    }
                }
            }
            Section {
                Button {
                    showingDateOfBirthAlert = true
                } label: {
                    HStack {
                        Text("Choose Date of Birth")
                        Spacer()
                        Image(systemName: "calendar")
                            .frame(width: imageScale * scale, height: imageScale * scale)
                    }
                }
            }
            Section {
                Button {
                    showingAgeAlert = true
                } label: {
                    HStack {
                        Text("Enter Age")
                        Spacer()
                        Image(systemName: "keyboard")
                            .frame(width: imageScale * scale, height: imageScale * scale)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        AgeForm()
    }
}
#Preview {
    NavigationView {
        AgeForm(isPast: true)
    }
}
