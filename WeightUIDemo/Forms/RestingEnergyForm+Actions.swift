import SwiftUI

extension RestingEnergyForm {
    func undo() {
        isDirty = false
        source = .equation
        equation = .mifflinStJeor
        intervalType = .average
        interval = .init(3, .day)
        applyCorrection = true
        correctionType = .divide
        correction = 2
        value = 2798
        customValue = 2798
        customValueTextAsDouble = 2798
        customValueText = "2798"
        correctionTextAsDouble = 2
        correctionText = "2"
    }
    
    func setIsDirty() {
        isDirty = source != .equation
        || equation != .mifflinStJeor
        || intervalType != .average
        || interval != .init(3, .day)
        || applyCorrection != true
        || correctionType != .divide
        || correction != 2
        || value != 2798
        || customValue != 2798
        || customValueTextAsDouble != 2798
        || customValueText != "2798"
        || correctionTextAsDouble != 2
        || correctionText != "2"
    }
    
    func submitCustomValue() {
        withAnimation {
            customValue = customValueTextAsDouble
            value = customValue
            setIsDirty()
        }
    }

    func submitCorrection() {
        withAnimation {
            correction = correctionTextAsDouble
            setIsDirty()
        }
    }
    
    func save() {
        
    }
}
