import SwiftUI

struct MeasurementCell: View {
    enum ImageType {
        case healthKit
        case systemImage(String)
    }
    
    let imageType: ImageType
    let timeString: String
    let isDisabled: Bool
    @Binding var showDeleteButton: Bool
    let deleteAction: () -> ()
    
    let double: Double
    let int: Int?
    let doubleUnitString: String
    let intUnitString: String?

    var body: some View {
        HStack {
            deleteButton
                .opacity(isDisabled ? 0.6 : 1)
            image
            Text(timeString)
                .foregroundStyle(isDisabled ? .secondary : .primary)
            Spacer()
            Text(string)
                .foregroundStyle(isDisabled ? .secondary : .primary)
        }
    }
    
    @ViewBuilder
    var image: some View {
        switch imageType {
        case .healthKit:
            Image("AppleHealthIcon")
                .resizable()
                .frame(width: 24, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(.systemGray3), lineWidth: 0.5)
                )
        case .systemImage(let imageName):
            Image(systemName: imageName)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(Color(.systemGray4))
                )
        }
    }
    
    @ViewBuilder
    var deleteButton: some View {
        if showDeleteButton {
            Button {
                deleteAction()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .imageScale(.large)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
    
    var string: String {
        let double = "\(double.cleanHealth) \(doubleUnitString)"
        return if let int, let intUnitString {
            "\(int) \(intUnitString) \(double)"
        } else {
            double
        }
    }
}

struct MeasurementCellNew: View {
    enum ImageType {
        case healthKit
        case systemImage(String)
    }
    
    let measurement: any Measurable
    
//    let imageType: ImageType
//    let timeString: String
    let isDisabled: Bool
    @Binding var showDeleteButton: Bool
    let deleteAction: () -> ()
    
    let double: Double
    let int: Int?
    let doubleUnitString: String
    let intUnitString: String?

    var body: some View {
        HStack {
            deleteButton
                .opacity(isDisabled ? 0.6 : 1)
            image
            Text(measurement.timeString)
                .foregroundStyle(isDisabled ? .secondary : .primary)
            Spacer()
            Text(string)
                .foregroundStyle(isDisabled ? .secondary : .primary)
        }
    }
    
    @ViewBuilder
    var image: some View {
        switch measurement.imageType {
        case .healthKit:
            Image("AppleHealthIcon")
                .resizable()
                .frame(width: 24, height: 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(.systemGray3), lineWidth: 0.5)
                )
        case .systemImage(let imageName):
            Image(systemName: imageName)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(Color(.systemGray4))
                )
        }
    }
    
    @ViewBuilder
    var deleteButton: some View {
        if showDeleteButton {
            Button {
                deleteAction()
            } label: {
                Image(systemName: "minus.circle.fill")
                    .imageScale(.large)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
    }
    
    var string: String {
        let double = "\(double.cleanHealth) \(doubleUnitString)"
        return if let int, let intUnitString {
            "\(int) \(intUnitString) \(double)"
        } else {
            double
        }
    }
}
