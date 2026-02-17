import Foundation
import SwiftData

@Model
final class MonthlyGoal {
    var month: Int
    var year: Int
    var targetDistanceKm: Double

    init(month: Int, year: Int, targetDistanceKm: Double) {
        self.month = month
        self.year = year
        self.targetDistanceKm = targetDistanceKm
    }

    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        var components = DateComponents()
        components.month = month
        components.year = year
        guard let date = Calendar.current.date(from: components) else { return "" }
        return formatter.string(from: date)
    }

    var formattedTarget: String {
        String(format: "%.1f km", targetDistanceKm)
    }
}
