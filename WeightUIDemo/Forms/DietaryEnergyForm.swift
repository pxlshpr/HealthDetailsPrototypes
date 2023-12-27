import SwiftUI

struct DietaryEnergyForm: View {
    
    let pastDate: Date?
    @State var isEditing: Bool
    @State var isDirty: Bool = false
    
    @State var value: Double = 2893

    @Binding var isPresented: Bool

    @State var presentedData: ListData? = nil
    
    init(pastDate: Date? = nil, isPresented: Binding<Bool> = .constant(true)) {
        self.pastDate = pastDate
        _isPresented = isPresented
        _isEditing = State(initialValue: true)
    }

    var body: some View {
        List {
            notice
            list
            explanation
        }
        .navigationTitle("Dietary Energy")
        .toolbar { toolbarContent }
        .sheet(item: $presentedData) { data in
            DietaryEnergyPointForm(
                dateString: data.dateString,
                pastDate: pastDate
            )
        }
    }
    
    var list: some View {
        Section {
            ForEach(listData, id: \.self) { data in
                Button {
                    presentedData = data
                } label: {
                    DietaryEnergyCell(listData: data)
                }
            }
        }
    }
    
    var isPast: Bool {
        pastDate != nil
    }
    
    @ViewBuilder
    var notice: some View {
        if let pastDate {
            NoticeSection.legacy(
                pastDate,
                isEditing: $isEditing
            )
        }
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            bottomToolbarContent(
                value: value,
                valueString: value.formattedEnergy,
                isDisabled: !isEditing,
                unitString: "kcal / day"
            )
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    isPresented = false
                }
                .fontWeight(.semibold)
            }
        }
    }
    
    func save() {
        
    }
    
    func undo() {
        isDirty = false
        value = 2893
    }

    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("The daily dietary energy for at least one of these days is required. Your daily energy totals from your log will be used by default. \n\nFor days that have inaccurate or incomplete logs, you an choose to not include them, so that your calculation isn't affected.\n\nAny days not included will be assigned the average dietary energy. If you did a full day fast on any of these days, make sure they are marked, so that they aren't assigned the average.")
            }
        }
    }
    
    struct ListData: Hashable, Identifiable {
        
        let type: DietaryEnergyPointType
        let dateString: String
        let valueString: String
        
        init(_ type: DietaryEnergyPointType, _ dateString: String, _ valueString: String) {
            self.type = type
            self.dateString = dateString
            self.valueString = valueString
        }
        
        var id: String { dateString }
    }
    
    let listData: [ListData] = [
        .init(.log, "22 Dec", "2,345 kcal"),
        .init(.log, "20 Dec", "3,012 kcal"),
        .init(.custom, "19 Dec", "0 kcal"),
        .init(.notIncluded, "18 Dec", "1,983 kcal"),
        .init(.healthKit, "17 Dec", "1,725 kcal"),
        .init(.notIncluded, "16 Dec", "1,983 kcal"),
        .init(.log, "15 Dec", "2,831 kcal"),
    ]
}

struct DietaryEnergyCell: View {
    
    let listData: DietaryEnergyForm.ListData
    var body: some View {
        HStack {
            dateText
            Spacer()
            detail
            image
        }
    }
    
    @ViewBuilder
    var image: some View {
        switch listData.type {
        case .healthKit:
            Image("AppleHealthIcon")
                .resizable()
                .frame(width: 24, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(.systemGray3), lineWidth: 0.5)
                )
        case .notIncluded:
            EmptyView()
        default:
            Image(systemName: listData.type.image)
                .frame(width: 24, height: 24)
                .foregroundStyle(listData.type.foregroundColor)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(listData.type.backgroundColor)
                )
        }
    }
    
    @ViewBuilder
    var detail: some View {
        if listData.type == .notIncluded {
            Text("Not Included")
                .foregroundStyle(Color(.secondaryLabel))
        } else {
            Text(listData.valueString)
                .foregroundStyle(Color(.label))
        }
    }
    
    var dateText: some View {
        Text(listData.dateString)
            .foregroundStyle(Color(.label))
    }
}


#Preview("Current") {
    NavigationView {
        DietaryEnergyForm()
    }
}

#Preview("Past") {
    NavigationView {
        DietaryEnergyForm(pastDate: MockPastDate)
    }
}
