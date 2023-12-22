import SwiftUI
import SwiftSugar

struct AgeForm: View {
    
    @Environment(\.dismiss) var dismiss

    @ScaledMetric var scale: CGFloat = 1
    let imageScale: CGFloat = 24
    
    @State var hasAppeared = false
    
    @State var showingAgeAlert = false
    @State var showingDateOfBirthAlert = false

    @State var age: Int? = nil
    @State var ageTextAsInt: Int? = nil
    @State var ageText: String = ""
    @State var dateOfBirth = DefaultDateOfBirth
    @State var chosenDateOfBirth = DefaultDateOfBirth

    var body: some View {
        NavigationStack {
            Group {
                if hasAppeared {
                    Form {
                        explanation
                        content
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
            NavigationStack {
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
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }

    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("Your age may be used when:")
                Label {
                    Text("Calculating your estimated resting energy.")
                } icon: {
                    Circle()
                        .foregroundStyle(Color(.label))
                        .frame(width: 5, height: 5)
                }
                Label {
                    Text("Picking daily values for micronutrients.")
                } icon: {
                    Circle()
                        .foregroundStyle(Color(.label))
                        .frame(width: 5, height: 5)
                }
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
        
    var content: some View {
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
    AgeForm()
}

let DefaultAge = 20
let DefaultDateOfBirth = Date.now.moveYearBy(-DefaultAge)

extension Date {
    func moveYearBy(_ yearIncrement: Int) -> Date {
        var components = DateComponents()
        components.year = yearIncrement
        return Calendar.current.date(byAdding: components, to: self)!
    }

    var dateComponentsWithoutTime: DateComponents {
        Calendar.current.dateComponents(
            [.year, .month, .day],
            from: self
        )
    }
    
    var age: Int {
        dateComponentsWithoutTime.age
    }
}
public extension DateComponents {
    var age: Int {
        let calendar = Calendar.current
        let now = Date().dateComponentsWithoutTime
        let ageComponents = calendar.dateComponents([.year], from: self, to: now)
        return ageComponents.year ?? 0
    }
}

extension Int {
    var dateOfBirth: Date {
        Date.now.moveYearBy(-self)
    }
}

extension Double {
    var formattedEnergy: String {
        let rounded = self.rounded()
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let number = NSNumber(value: Int(rounded))
        
        guard let formatted = numberFormatter.string(from: number) else {
            return "\(Int(rounded))"
        }
        return formatted
    }
}
