import SwiftUI

struct HealthDetailsForm: View {
    
    @Bindable var healthProvider: HealthProvider
    
    @Binding var isPresented: Bool
    @State var dismissDisabled: Bool = false
    
    init(
        healthProvider: HealthProvider,
        isPresented: Binding<Bool>
    ) {
        self.healthProvider = healthProvider
        _isPresented = isPresented
    }
    
    var body: some View {
        NavigationView {
            form
                .navigationTitle("Health Details")
                .navigationBarTitleDisplayMode(.large)
                .toolbar { toolbarContent }
        }
//        .interactiveDismissDisabled(dismissDisabled)
        .interactiveDismissDisabled(true)
    }
    
    var form: some View {
        Form {
            dateSection
            Section {
                link(for: .maintenance)
            }
            Section {
                link(for: .weight)
                link(for: .height)
            }
            Section {
                link(for: .leanBodyMass)
                link(for: .fatPercentage)
            }
            Section {
                link(for: .age)
                link(for: .biologicalSex)
//                if shouldShowSmokingStatus {
                    link(for: .smokingStatus)
//                }
                if shouldShowPregnancyStatus {
                    link(for: .preganancyStatus)
                }
            }
        }
    }
    
    var shouldShowPregnancyStatus: Bool {
        healthProvider.healthDetails.biologicalSex == .female
//        && healthProvider.healthDetails.smokingStatus != .smoker
    }
    
    var shouldShowSmokingStatus: Bool {
        !healthProvider.healthDetails.pregnancyStatus.isPregnantOrLactating
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
    
    func link(for healthDetail: HealthDetail) -> some View {
        var details: HealthDetails { healthProvider.healthDetails }
        
//        @ViewBuilder
//        var secondaryText: some View {
//            if let secondary = details.secondaryValueString(for: healthDetail, healthProvider.settingsProvider) {
//                Text(secondary)
//                    .foregroundStyle(.secondary)
//            }
//        }
        
        var primaryText: some View {
            Text(details.valueString(for: healthDetail, healthProvider.settingsProvider))
                .foregroundStyle(details.hasSet(healthDetail) ? .primary : .secondary)
        }
        
        return NavigationLink {
            sheet(for: healthDetail)
        } label: {
            HStack {
                Text(healthDetail.name)
                Spacer()
                HStack(spacing: 4) {
//                    secondaryText
                    primaryText
                }
            }
        }
    }
    
    @ViewBuilder
    var dateSection: some View {
        if !healthProvider.healthDetails.date.isToday {
            NoticeSection.legacy(healthProvider.healthDetails.date)
//            Section {
//                HStack {
//                    Text("Date")
//                    Spacer()
//                    Text(healthProvider.healthDetails.date.shortDateString)
//                }
//            }
        }
    }
    
    @ViewBuilder
    func sheet(for route: HealthDetail) -> some View {
        switch route {
        case .maintenance:
            MaintenanceForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        case .leanBodyMass:
            LeanBodyMassForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        case .fatPercentage:
            FatPercentageForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        case .weight:
            WeightForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        case .height:
            HeightForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        case .age:
            AgeForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        case .biologicalSex:
            BiologicalSexForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        case .preganancyStatus:
            PregnancyStatusForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        case .smokingStatus:
            SmokingStatusForm(
                healthProvider: healthProvider,
                isPresented: $isPresented
            )
        }
    }
}

//#Preview("Current") {
//    MockCurrentHealthDetailsForm()
//}
//
//#Preview("Past") {
//    MockPastHealthDetailsForm()
//}

#Preview("DemoView") {
    DemoView()
}
