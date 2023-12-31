import SwiftUI

struct DatePickerSheet: View {
    
    @Environment(\.dismiss) var dismiss
    
    @Binding var date: Date
    @State var pickedDate: Date
    let initialDate: Date
    let title: String

    init(
        _ title: String,
        _ date: Binding<Date>
    ) {
        _date = date
        self.initialDate = date.wrappedValue
        _pickedDate = State(initialValue: date.wrappedValue)
        self.title = title
    }
    
    var body: some View {
        NavigationView {
            picker
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled(isDirty)
    }
    
    var isDirty: Bool {
        pickedDate != date
    }
    
    var picker: some View {
        DatePicker(
            title,
            selection: $pickedDate,
            displayedComponents: [.date]
        )
        .datePickerStyle(.graphical)
    }
    
    var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    date = pickedDate
                    dismiss()
                }
                .fontWeight(.semibold)
                .disabled(!isDirty)
            }
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}
