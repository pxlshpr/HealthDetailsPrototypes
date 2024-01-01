import SwiftUI
import PrepShared

struct SettingsForm: View {
    
    @Bindable var settingsProvider: SettingsProvider
    @Binding var isPresented: Bool
    
    init(
        _ settingsProvider: SettingsProvider = SettingsProvider(settings: .init()),
        isPresented: Binding<Bool> = .constant(false)
    ) {
        self.settingsProvider = settingsProvider
        _isPresented = isPresented
    }
    
    var body: some View {
        NavigationView {
            Form {
                heightUnitPicker
                bodyMassUnitPicker
            }
            .navigationTitle("Settings")
        }
    }
    
    var heightUnitPicker: some View {
        let binding = Binding<HeightUnit>(
            get: { settingsProvider.settings.heightUnit },
            set: { newValue in
                settingsProvider.saveHeightUnit(newValue)
            }
        )
        return PickerSection(binding, "Height Unit")
    }
    
    var bodyMassUnitPicker: some View {
        let binding = Binding<BodyMassUnit>(
            get: { settingsProvider.settings.bodyMassUnit },
            set: { newValue in
                settingsProvider.saveBodyMassUnit(newValue)
            }
        )
        return PickerSection(binding, "Body Mass Unit")
    }
}

#Preview {
    SettingsForm()
}
