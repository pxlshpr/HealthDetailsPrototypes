import SwiftUI
import SwiftSugar

struct AgeForm_Past: View {
    
    @Environment(\.dismiss) var dismiss

    @ScaledMetric var scale: CGFloat = 1
    @State var hasAppeared = false
    
    @State var showingAgeAlert = false
    @State var showingDateOfBirthAlert = false

    @State var age: Int? = 36
    @State var ageTextAsInt: Int? = 36
    @State var ageText: String = "36"
    @State var dateOfBirth = 36.dateOfBirth
    @State var chosenDateOfBirth = 36.dateOfBirth

    @State var isEditing = false

    var body: some View {
        NavigationView {
            Group {
                if hasAppeared {
                    Form {
                        explanation
                        if !isEditing {
                            notice
                        } else {
                            actions
                        }
                    }
                } else {
                    Color.clear
                }
            }
            .navigationTitle("Age")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                hasAppeared = true
            }
        }
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

    var isDisabled: Bool {
        !isEditing
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
                            .foregroundStyle(isDisabled ? .secondary : .primary)
                        Text("years")
                            .font(LargeUnitFont)
                            .foregroundStyle(isDisabled ? .tertiary : .secondary)
                    } else {
                        Text("Not Set")
                            .font(NotSetFont)
                            .foregroundStyle(isDisabled ? .tertiary : .secondary)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        withAnimation {
                            isEditing = false
                        }
                    } else {
                        withAnimation {
                            isEditing = true
                        }
                    }
                }
                .fontWeight(.semibold)
            }
            ToolbarItem(placement: .topBarLeading) {
                if isEditing {
                    Button("Cancel") {
                        withAnimation {
                            isEditing = false
                        }
                    }
                }
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
    
    let imageScale: CGFloat = 20
    
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
//                    Label(
//                        title: { Text("Read from Apple Health") },
//                        icon: {
//                            Image("AppleHealthIcon")
//                                .resizable()
//                                .frame(width: 24, height: 24)
//                                .overlay(
//                                    RoundedRectangle(cornerRadius: 5)
//                                        .stroke(Color(.systemGray3), lineWidth: 0.5)
//                                )
//                        }
//                    )
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
//                    Label(
//                        title: { Text("Choose Date of Birth") },
//                        icon: { Image(systemName: "calendar") }
//                    )
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
//                    Label(
//                        title: { Text("Enter Age") },
//                        icon: { Image(systemName: "keyboard") }
//                    )
                }
            }
        }
    }
}

#Preview {
    AgeForm_Past()
}
