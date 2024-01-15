import Foundation

public enum MaintenanceCalculationError: Int, Error, Codable {
    case noWeightData = 1
    case noNutritionData
    case noWeightOrNutritionData
    case weightChangeExceedsNutrition
    
    var message: String {
        switch self {
        case .noWeightData:
//            "You do not have enough weight data over the prior week to make a calculation."
            "You need to set your weight change to make a calculation."
        case .noNutritionData:
            "You need to have at least one day's dietary energy to make a calculation."
        case .noWeightOrNutritionData:
            "You need to set your weight change and dietary energy consumed to make an adaptive calculation."
        case .weightChangeExceedsNutrition:
            "Your weight gain far exceeds the dietary energy, making the calculation invalid. Make sure you have accounted for all the dietary energy you consumed."
        }
    }
    
    var title: String {
        switch self {
        case .noWeightData:
            "No Weight Change"
        case .noNutritionData:
            "No Dietary Energy"
        case .noWeightOrNutritionData:
            "No Weight Change and Dietary Energy"
        case .weightChangeExceedsNutrition:
            "Invalid Data"
        }
    }
}
