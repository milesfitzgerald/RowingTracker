import SwiftUI
import SwiftData
import UIKit

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DashboardViewModel()
    @State private var showAddSession = false
    @State private var showGoalSheet = false
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.15, blue: 0.3),
                        Color(red: 0.12, green: 0.22, blue: 0.4)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // River scene
                        RiverSceneView(progress: viewModel.progress)
                            .frame(height: 220)
                            .padding(.horizontal)

                        // Progress card
                        if viewModel.currentGoal != nil {
                            ProgressCard(viewModel: viewModel)
                        } else {
                            NoGoalCard()
                        }

                        // Log session button
                        LogSessionButton {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.prepare()
                            generator.impactOccurred()
                            showAddSession = true
                        }

                        // Recent sessions
                        if !viewModel.recentSessions.isEmpty {
                            RecentSessionsCard(sessions: viewModel.recentSessions)
                        }
                    }
                    .padding()
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                }

                // Confetti overlay
                if viewModel.showConfetti {
                    PartyEmojiView(key: UUID())
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .navigationTitle("RowTracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showGoalSheet = true
                    } label: {
                        Image(systemName: "target")
                            .foregroundStyle(.white)
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showAddSession) {
                AddSessionSheet { date, durationSeconds, distanceKm in
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                        viewModel.addSession(
                            date: date,
                            durationSeconds: durationSeconds,
                            distanceKm: distanceKm,
                            modelContext: modelContext
                        )
                    }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showGoalSheet) {
                GoalSheet(
                    currentGoal: viewModel.currentGoal,
                    onSetGoal: { distance in
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            viewModel.setGoal(distanceKm: distance, modelContext: modelContext)
                        }
                    },
                    onReset: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            viewModel.resetMonth(modelContext: modelContext)
                        }
                    }
                )
                .presentationDetents([.medium])
            }
            .task {
                viewModel.load(modelContext: modelContext)
                withAnimation(.easeOut(duration: 0.5)) {
                    appeared = true
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    viewModel.load(modelContext: modelContext)
                }
            }
        }
    }
}

// MARK: - Progress Card

private struct ProgressCard: View {
    let viewModel: DashboardViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(viewModel.currentMonthName)
                    .font(.headline)
                Spacer()
                Text("\(viewModel.progressPercentage)%")
                    .font(.title2.bold())
                    .foregroundStyle(viewModel.progress >= 1.0 ? .green : .blue)
            }

            ProgressView(value: viewModel.progress)
                .tint(viewModel.progress >= 1.0 ? .green : .blue)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: viewModel.progress)

            HStack {
                Text(String(format: "%.1f / %.1f km", viewModel.totalDistance, viewModel.currentGoal?.targetDistanceKm ?? 0))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Divider()

            HStack(spacing: 24) {
                StatItem(
                    icon: "figure.rowing",
                    value: "\(viewModel.currentMonthSessions.count)",
                    label: "Sessions"
                )
                StatItem(
                    icon: "clock",
                    value: viewModel.formattedTotalDuration,
                    label: "Total Time"
                )
                StatItem(
                    icon: "arrow.right",
                    value: String(format: "%.1f km", viewModel.totalDistance),
                    label: "Distance"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - No Goal Card

private struct NoGoalCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 36))
                .foregroundStyle(.blue.opacity(0.6))
            Text("No Goal Set")
                .font(.headline)
            Text("Tap the target icon to set a monthly distance goal and watch your rower make progress!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Log Session Button

private struct LogSessionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Log Session")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

// MARK: - Recent Sessions Card

private struct RecentSessionsCard: View {
    let sessions: [RowingSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Sessions")
                .font(.headline)
                .padding(.bottom, 4)

            ForEach(sessions, id: \.date) { session in
                HStack {
                    Image(systemName: "figure.rowing")
                        .foregroundStyle(.blue)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.formattedDate)
                            .font(.subheadline.bold())
                        Text(session.formattedDuration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(session.formattedDistance)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
                if session.date != sessions.last?.date {
                    Divider()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Party Emoji View

struct PartyEmojiView: View {
    let key: UUID
    let emojis = ["🎉", "🎊", "✨", "🥳", "🏆", "🚣", "⭐️", "💪"]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    ConfettiEmoji(
                        emoji: emojis[index],
                        screenWidth: geometry.size.width,
                        screenHeight: geometry.size.height,
                        delay: Double(index) * 0.1,
                        key: key
                    )
                }
            }
        }
    }
}

struct ConfettiEmoji: View {
    let emoji: String
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let delay: Double
    let key: UUID

    @State private var yOffset: CGFloat = -100
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        Text(emoji)
            .font(.system(size: 50))
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(x: xOffset, y: yOffset)
            .onAppear {
                let randomX = CGFloat.random(in: -screenWidth / 2...screenWidth / 2)
                let randomRotation = Double.random(in: -360...360)
                let randomDuration = Double.random(in: 1.5...2.5)

                xOffset = randomX

                withAnimation(.easeOut(duration: randomDuration).delay(delay)) {
                    yOffset = screenHeight + 100
                    opacity = 0
                }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(delay)) {
                    scale = 1.0
                    opacity = 1.0
                }
                withAnimation(.linear(duration: randomDuration).delay(delay)) {
                    rotation = randomRotation
                }
            }
    }
}
