import SwiftUI

func topToolbarContent(
    isEditing: Binding<Bool>,
    isPast: Bool,
    dismissAction: @escaping () -> ()
) -> some ToolbarContent {
    Group {
        ToolbarItem(placement: .topBarTrailing) {
            Button(isEditing.wrappedValue ? "Done" : "Edit") {
                if isEditing.wrappedValue {
                    if isPast {
                        withAnimation {
                            isEditing.wrappedValue = false
                        }
                    } else {
                        dismissAction()
                    }
                } else {
                    withAnimation {
                        isEditing.wrappedValue = true
                    }
                }
            }
            .fontWeight(.semibold)
        }
        ToolbarItem(placement: .topBarLeading) {
            if isPast, isEditing.wrappedValue {
                Button("Cancel") {
                    withAnimation {
                        isEditing.wrappedValue = false
                    }
                }
            }
        }
    }
}
