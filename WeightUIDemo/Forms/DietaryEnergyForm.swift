import SwiftUI

struct DietaryEnergyForm: View {
    
    let pastDate: Date?
    @State var isEditing: Bool
    
    @State var value: Double? = 2893

    @Binding var isPresented: Bool
    @Binding var dismissDisabled: Bool

    init(
        pastDate: Date? = nil,
        isPresented: Binding<Bool> = .constant(true),
        dismissDisabled: Binding<Bool> = .constant(false)
    ) {
        self.pastDate = pastDate
        _isPresented = isPresented
        _dismissDisabled = dismissDisabled
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
        .safeAreaInset(edge: .bottom) { bottomValue }
    }
    
    var bottomValue: some View {
        BottomValue(
            value: $value,
            valueString: Binding<String?>(
                get: { value?.formattedEnergy },
                set: { _ in }
            ),
            isDisabled: .constant(true),
            unitString: "kcal/day"
        )
    }
    
    var list: some View {
        Section {
            ForEach(listData, id: \.self) { data in
                NavigationLink {
                    DietaryEnergyPointForm(
                        dateString: data.dateString,
                        pastDate: pastDate,
                        isPresented: $isPresented,
                        dismissDisabled: $dismissDisabled
                    )
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
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isPresented = false
            } label: {
                CloseButtonLabel()
            }
//            Button("Done") {
//                isPresented = false
//            }
//            .fontWeight(.semibold)
        }
    }
    
    func save() {
        
    }
    
    func undo() {
        value = 2893
    }

    var explanation: some View {
        Section {
            Text("This is how much dietary energy you consumed over the period for which you are calculating your Adaptive Maintenance.")
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
        .init(.useAverage, "18 Dec", "1,983 kcal"),
        .init(.healthKit, "17 Dec", "1,725 kcal"),
        .init(.useAverage, "16 Dec", "1,983 kcal"),
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
        case .useAverage:
            EmptyView()
//            Color.clear
//                .frame(width: 24, height: 24)
//                .opacity(0)
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
        if listData.type == .useAverage {
//            Text("Not Included")
            Text("Exclude and Use Average")
//                .foregroundStyle(Color(.label))
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
