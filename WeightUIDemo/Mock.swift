import SwiftUI

struct MockCurrentHealthDetailsForm: View {
    
    @State var provider: HealthProvider
    @Binding var isPresented: Bool

    init(isPresented: Binding<Bool> = .constant(true)) {
        _isPresented = isPresented
        
        let healthDetails = fetchHealthDetailsFromDocuments(Date.now)
        let provider = HealthProvider(isCurrent: true, healthDetails: healthDetails)
        _provider = State(initialValue: provider)
    }

    var body: some View {
        HealthDetailsForm(provider: provider)
    }
}

struct MockPastHealthDetailsForm: View {
    
    @State var provider: HealthProvider
    @Binding var isPresented: Bool
    
    init(isPresented: Binding<Bool> = .constant(true)) {
        _isPresented = isPresented
        
        let healthDetails = fetchHealthDetailsFromDocuments(Date(fromDateString: "2023_12_01")!)
        let provider = HealthProvider(isCurrent: false, healthDetails: healthDetails)
        _provider = State(initialValue: provider)
    }

    var body: some View {
        HealthDetailsForm(provider: provider)
    }
}


let MockCurrentProvider = HealthProvider(
    isCurrent: true,
    healthDetails: HealthDetails(
        date: Date.now,
        sex: .notSet
    )
)

let MockPastProvider = HealthProvider(
    isCurrent: false,
    healthDetails: HealthDetails(
        date: Date.now.moveDayBy(-1),
        sex: .male,
        age: .init(value: 20)
    )
)

//MARK: Reusable

func getDocumentsDirectory() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}

func fetchHealthDetailsFromDocuments(_ date: Date) -> HealthDetails {
    let filename = "\(date.dateString).json"
    let url = getDocumentsDirectory().appendingPathComponent(filename)
    do {
        print("Fetching HealthDetails from documents: \(filename)")
        let data = try Data(contentsOf: url)
        let healthDetails = try JSONDecoder().decode(HealthDetails.self, from: data)
        return healthDetails
    } catch {
        print("Couldn't fetch, creating")
        let healthDetails = HealthDetails(date: date)
        saveHealthDetailsInDocuments(healthDetails)
        return healthDetails
    }
}

func saveHealthDetailsInDocuments(_ healthDetails: HealthDetails) {
    do {
        let filename = "\(healthDetails.date.dateString).json"
        print("Saving HealthDetails to documents: \(filename)")
        let url = getDocumentsDirectory().appendingPathComponent(filename)
        let json = try JSONEncoder().encode(healthDetails)
        try json.write(to: url)
    } catch {
        print("Error Saving HealthDetails to documents")
        fatalError()
    }
}
