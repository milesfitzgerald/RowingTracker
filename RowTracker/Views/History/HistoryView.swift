import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RowingSession.date, order: .reverse)
    private var allSessions: [RowingSession]

    private var groupedSessions: [(String, [RowingSession])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: allSessions) { session in
            formatter.string(from: session.date)
        }

        return grouped
            .sorted { lhs, rhs in
                guard let lhsDate = lhs.value.first?.date,
                      let rhsDate = rhs.value.first?.date else { return false }
                return lhsDate > rhsDate
            }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allSessions.isEmpty {
                    EmptyHistoryView()
                } else {
                    List {
                        ForEach(groupedSessions, id: \.0) { monthName, sessions in
                            Section {
                                ForEach(sessions, id: \.date) { session in
                                    SessionRow(session: session)
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        modelContext.delete(sessions[index])
                                    }
                                    try? modelContext.save()
                                }
                            } header: {
                                HStack {
                                    Text(monthName)
                                    Spacer()
                                    let total = sessions.reduce(0) { $0 + $1.distanceKm }
                                    Text(String(format: "%.1f km", total))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

// MARK: - Session Row

private struct SessionRow: View {
    let session: RowingSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.subheadline.bold())
                Text(session.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(session.formattedDistance)
                .font(.headline)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Empty State

private struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 56))
                .foregroundStyle(.blue.opacity(0.4))
            Text("No Sessions Yet")
                .font(.title3.bold())
            Text("Your rowing sessions will appear here once you start logging them.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}
