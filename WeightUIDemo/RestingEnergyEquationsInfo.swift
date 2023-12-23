import SwiftUI

struct RestingEnergyEquationsInfo: View {
    
    @Environment(\.dismiss) var dismiss
    @State var hasAppeared = false
    
    var body: some View {
        NavigationStack {
            Group {
                if hasAppeared {
                    form
                } else {
                    Color.clear
                }
            }
            .navigationTitle("Equations")
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: appeared)
            .toolbar { toolbarContent }
        }
    }
    
    func appeared() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            hasAppeared = true
        }
    }
    
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Done") {
                dismiss()
            }
            .fontWeight(.semibold)
        }
    }
    
    var form: some View {
        Form {
            ForEach(RestingEnergyEquation.inOrderOfYear, id: \.self) {
                section(for: $0)
            }
        }
    }
    
    func section(for equation: RestingEnergyEquation) -> some View {
        var header: some View {
            HStack(alignment: .bottom) {
                Text(equation.name)
                    .textCase(.none)
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color(.label))
                 Spacer()
                 Text(equation.year)
                     .textCase(.none)
                     .font(.system(.title3, design: .rounded, weight: .medium))
                     .foregroundStyle(Color(.label))
            }
        }
        
        var variablesRow: some View {
            HStack(alignment: .firstTextBaseline) {
                Text("Uses")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(equation.variablesDescription)
                    .multilineTextAlignment(.trailing)
            }
        }
        
        return Section(header: header) {
            Text(equation.description)
            variablesRow
        }
    }
}
