import SwiftUI

struct DietaryEnergyForm: View {
    
    let isPast: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                explanation
                list
            }
            .navigationTitle("Dietary Energy")
        }
    }
    
    var explanation: some View {
        Section {
            VStack(alignment: .leading) {
                Text("The daily dietary energy for at least one of these days is required. Your daily energy totals from your log will be used by default. \n\nFor days that have inaccurate or incomplete logs, you an choose to not include them, so that your calculation isn't affected.\n\nAny days not included will be assigned the average dietary energy. If you did a full day fast on any of these days, make sure they are marked, so that they aren't assigned the average.")
            }
        }
    }
    
    struct ListData: Hashable {
        
        let type: DietaryEnergyPointType
        let dateString: String
        let valueString: String
        
        init(_ type: DietaryEnergyPointType, _ dateString: String, _ valueString: String) {
            self.type = type
            self.dateString = dateString
            self.valueString = valueString
        }
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
    
    func cell(for listData: ListData) -> some View {
        
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
                    .foregroundStyle(.secondary)
            } else {
                Text(listData.valueString)
            }
        }
        
        var label: some View {
            Text(listData.dateString)
        }
        
        return HStack {
            label
            Spacer()
            detail
            image
        }
    }
    
    var list: some View {
        Section {
            ForEach(listData, id: \.self) { data in
                NavigationLink {
                    if isPast {
                        DietaryEnergyPointForm_Past()
                    } else {
                        DietaryEnergyPointForm(dateString: data.dateString)
                    }
                } label: {
                    cell(for: data)
                }
            }
        }
    }
}

#Preview {
    DietaryEnergyForm(isPast: false)
}
