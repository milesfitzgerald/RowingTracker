import Foundation
import SwiftData

@Model
final class RowingSession {
    var date: Date
    var durationSeconds: Int
    var distanceKm: Double
    var note: String?

    init(
        date: Date = .now,
        durationSeconds: Int,
        distanceKm: Double,
        note: String? = nil
    ) {
        self.date = date
        self.durationSeconds = durationSeconds
        self.distanceKm = distanceKm
        self.note = note
    }

    var formattedDuration: String {
        let hours = durationSeconds / 3600
        let minutes = (durationSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var formattedDistance: String {
        String(format: "%.1f km", distanceKm)
    }

    var formattedDate: String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }
}
