import Foundation

struct WeightChangePoint: Hashable, Codable {
    
    var date: Date
    var kg: Double?
    
//    var weight: HealthDetails.Weight?
    var movingAverageInterval: HealthInterval? = .init(7, .day)
//    var movingAverage: MovingAverage?
    
//    var defaultPoints: [MovingAverage.Point] {
//        if let points = movingAverage?.points {
//            points
//        } else if let weight {
//            [MovingAverage.Point(date: date, weight: weight)]
//        } else {
//            []
//        }
//    }
    
//    struct MovingAverage: Hashable, Codable {
//        var interval: HealthInterval = .init(7, .day)
//        var points: [Point]
//        
//        struct Point: Hashable, Codable, Identifiable {
//            var date: Date
//            var weight: HealthDetails.Weight
//            
//            var id: Date { date }
//        }
//    }
    
    init(
        date: Date,
        kg: Double? = nil,
//        weight: HealthDetails.Weight? = nil,
        movingAverageInterval: HealthInterval? = .init(7, .day)
//        movingAverage: MovingAverage? = nil
    ) {
        self.date = date
        self.kg = kg
//        self.weight = weight
        self.movingAverageInterval = movingAverageInterval
//        self.movingAverage = movingAverage
    }
}

extension Array where Element == HealthDetails.Weight {
//extension Array where Element == WeightChangePoint.MovingAverage.Point {
    var average: Double? {
        let values = self
//            .compactMap { $0.weight.weightInKg }
            .compactMap { $0.weightInKg }
        guard !values.isEmpty else { return nil }
        let sum = values.reduce(0) { $0 + $1 }
        return Double(sum) / Double(values.count)
    }
}
