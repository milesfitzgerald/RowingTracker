import Foundation
import SwiftData
import Observation
import UIKit

@Observable
final class DashboardViewModel {
    var currentGoal: MonthlyGoal?
    var currentMonthSessions: [RowingSession] = []
    var isLoading = false
    var showConfetti = false
    var previousProgress: Double = 0

    var totalDistance: Double {
        currentMonthSessions.reduce(0) { $0 + $1.distanceKm }
    }

    var totalDuration: Int {
        currentMonthSessions.reduce(0) { $0 + $1.durationSeconds }
    }

    var formattedTotalDuration: String {
        let hours = totalDuration / 3600
        let minutes = (totalDuration % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var progress: Double {
        guard let goal = currentGoal, goal.targetDistanceKm > 0 else { return 0 }
        return min(totalDistance / goal.targetDistanceKm, 1.0)
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }

    var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: .now)
    }

    var recentSessions: [RowingSession] {
        Array(currentMonthSessions.prefix(3))
    }

    // MARK: - Data Loading

    func load(modelContext: ModelContext) {
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let now = Date.now
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        // Fetch current month's goal
        let goalDescriptor = FetchDescriptor<MonthlyGoal>(
            predicate: #Predicate { goal in
                goal.month == currentMonth && goal.year == currentYear
            }
        )
        currentGoal = try? modelContext.fetch(goalDescriptor).first

        // Fetch current month's sessions
        let startOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

        let sessionDescriptor = FetchDescriptor<RowingSession>(
            predicate: #Predicate { session in
                session.date >= startOfMonth && session.date < endOfMonth
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        currentMonthSessions = (try? modelContext.fetch(sessionDescriptor)) ?? []
    }

    // MARK: - Actions

    func addSession(date: Date, durationSeconds: Int, distanceKm: Double, modelContext: ModelContext) {
        let oldProgress = progress

        let session = RowingSession(
            date: date,
            durationSeconds: durationSeconds,
            distanceKm: distanceKm
        )
        modelContext.insert(session)
        try? modelContext.save()

        load(modelContext: modelContext)

        // Haptic for session save
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)

        // Check if we just hit the goal
        if oldProgress < 1.0 && progress >= 1.0 {
            triggerGoalReachedCelebration()
        }

        previousProgress = oldProgress
    }

    func setGoal(distanceKm: Double, modelContext: ModelContext) {
        let calendar = Calendar.current
        let now = Date.now
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        if let existing = currentGoal {
            existing.targetDistanceKm = distanceKm
        } else {
            let goal = MonthlyGoal(month: currentMonth, year: currentYear, targetDistanceKm: distanceKm)
            modelContext.insert(goal)
        }
        try? modelContext.save()

        load(modelContext: modelContext)

        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    func resetMonth(modelContext: ModelContext) {
        // Delete current goal
        if let goal = currentGoal {
            modelContext.delete(goal)
        }

        // Delete current month sessions
        for session in currentMonthSessions {
            modelContext.delete(session)
        }
        try? modelContext.save()

        load(modelContext: modelContext)

        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }

    func deleteSession(_ session: RowingSession, modelContext: ModelContext) {
        modelContext.delete(session)
        try? modelContext.save()
        load(modelContext: modelContext)
    }

    // MARK: - Private

    private func triggerGoalReachedCelebration() {
        let notificationGenerator = UINotificationFeedbackGenerator()
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.success)

        let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
        impactGenerator.prepare()
        impactGenerator.impactOccurred(intensity: 1.0)

        showConfetti = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.showConfetti = false
        }
    }
}
