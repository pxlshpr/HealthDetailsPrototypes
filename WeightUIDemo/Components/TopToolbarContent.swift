import SwiftUI
import SwiftHaptics

func topToolbarContent(
    isEditing: Binding<Bool>,
    isDirty: Binding<Bool>,
    isPast: Bool,
    dismissAction: @escaping () -> (),
    undoAction: @escaping () -> (),
    saveAction: @escaping () -> ()
) -> some ToolbarContent {
    Group {
        ToolbarItem(placement: .topBarTrailing) {
            EditDoneButton(
                isEditing: isEditing,
                isDirty: isDirty,
                isPast: isPast,
                dismissAction: dismissAction,
                undoAction: undoAction,
                saveAction: saveAction
            )
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

struct EditDoneButton: View {
    @Binding var isEditing: Bool
    @Binding var isDirty: Bool
    let isPast: Bool
    let dismissAction: () -> ()
    let undoAction: () -> ()
    let saveAction: () -> ()

    @State var showingDirtyConfirmation: Bool = false
    
    var body: some View {
        buttons
            .fontWeight(.semibold)
            .confirmationDialog(
                "Are you sure",
                isPresented: $showingDirtyConfirmation
            ) {
                Button("Modify and Update Goals", role: .destructive) {
                    Haptics.successFeedback()
                    withAnimation {
                        saveAction()
                        isEditing = false
                    }
                }
                Button("Cancel", role: .cancel) {
                    Haptics.warningFeedback()
                    withAnimation {
                        undoAction()
                        isEditing = false
                    }
                }
            } message: {
                Text("This will update any dependent goals.")
            }
    }
    
    @ViewBuilder
    var buttons: some View {
        HStack {
            if isPast {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        tappedDone()
                    } else {
                        tappedEdit()
                    }
                }
                .disabled(disableRightButton)
            }
            if !(isPast && isEditing) {
                Button {
                    dismissAction()
                } label: {
                    CloseButtonLabel()
                }
            }
        }
    }
    
    var disableRightButton: Bool {
        isPast && isEditing && !isDirty
    }
    
    func tappedDone() {
        if isPast {
            if isDirty {
                showingDirtyConfirmation = true
            } else {
                withAnimation {
                    isEditing = false
                }
            }
        } else {
            dismissAction()
        }
    }
    
    func startEditing() {
        withAnimation {
            isEditing = true
        }
    }
    
    func tappedEdit() {
        startEditing()
    }
}
