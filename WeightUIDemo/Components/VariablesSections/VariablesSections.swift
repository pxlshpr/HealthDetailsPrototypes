import SwiftUI

struct VariablesSections: View {
    
    @Bindable var healthProvider: HealthProvider
    
    @Binding var healthDetails: [HealthDetail]
    let date: Date
    @Binding var isPresented: Bool
    let showHeader: Bool
    @Binding var isRequired: Bool
    
    /// The subject that the variables are for
    enum Subject {
        case equation
        case goal
        case dailyValue
        
        var name: String {
            switch self {
            case .equation:     "calculation"
            case .goal:         "goal"
            case .dailyValue:   "daily value"
            }
        }
        
        var title: String {
            switch self {
            case .equation:     "Equation Variables"
            case .goal:         "Goal Variables"
            case .dailyValue:   "Daily Value Variables"
            }
        }
    }
    let subject: Subject
    
    init(
        subject: Subject,
        healthDetails: Binding<[HealthDetail]>,
        isRequired: Binding<Bool> = .constant(true),
        healthProvider: HealthProvider,
        date: Date,
        isPresented: Binding<Bool>,
        showHeader: Bool = true
    ) {
        self.healthProvider = healthProvider
        self.subject = subject
        _isRequired = isRequired
        _healthDetails = healthDetails
        self.date = date
        _isPresented = isPresented
        self.showHeader = showHeader
    }
    
    var body: some View {
        nonTemporalSection
        temporalSections
    }
    
    @ViewBuilder
    var mainHeader: some View {
        if showHeader {
            Text(subject.title)
                .formTitleStyle()
        }
    }
    
    func link(for characteristic: HealthDetail) -> some View {
        NonTemporalVariableLink(
            healthProvider: healthProvider,
            subject: subject,
            characteristic: characteristic,
            date: date,
            isPresented: $isPresented
        )
    }
    
    var nonTemporalSection: some View {
        @ViewBuilder
        var footer: some View {
            if isRequired {
                Text("These are required for this \(subject.name).")
            }
        }
        return Group {
            if !nonTemporalHealthDetails.isEmpty {
                Section(header: mainHeader, footer: footer) {
                    ForEach(nonTemporalHealthDetails) {
                        link(for: $0)
                    }
                }
            }
        }
    }
    
    var temporalSections: some View {
        Group {
            ForEach(Array(temporalHealthDetails.enumerated()), id: \.offset) { index, healthDetail in
                temporalVariableSection(for: healthDetail, index: index)
            }
        }
    }
    
    func temporalVariableSection(for healthDetail: HealthDetail, index: Int) -> some View {
        TemporalVariableSection(
            healthProvider: healthProvider,
            subject: subject,
            healthDetail: healthDetail,
            date: date,
            isPresented: $isPresented,
            isRequired: $isRequired,
            shouldShowMainHeader: Binding<Bool>(
                get: { nonTemporalHealthDetails.isEmpty && index == 0 },
                set: { _ in }
            ),
            showHeader: showHeader
        )
    }
    
    var nonTemporalHealthDetails: [HealthDetail] {
        healthDetails.nonTemporalHealthDetails
    }
    
    var temporalHealthDetails: [HealthDetail] {
        healthDetails.temporalHealthDetails
    }
    
    var isPast: Bool {
        date.startOfDay < Date.now.startOfDay
    }
}

#Preview("Demo") {
    DemoView()
}
