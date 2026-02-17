import SwiftUI

struct GoalSheet: View {
    @Environment(\.dismiss) private var dismiss
    let currentGoal: MonthlyGoal?
    let onSetGoal: (Double) -> Void
    let onReset: () -> Void

    @State private var distanceText = ""
    @State private var showResetConfirmation = false
    @FocusState private var distanceFocused: Bool

    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: .now)
    }

    private var isValid: Bool {
        guard let distance = Double(distanceText), distance > 0 else { return false }
        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "target")
                            .font(.system(size: 40))
                            .foregroundStyle(.blue)
                        Text("\(currentMonthName) Goal")
                            .font(.title2.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                Section("Distance Goal") {
                    HStack {
                        TextField("e.g. 50", text: $distanceText)
                            .keyboardType(.decimalPad)
                            .focused($distanceFocused)
                            .font(.title3)
                        Text("km")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button {
                        guard let distance = Double(distanceText) else { return }
                        onSetGoal(distance)
                        dismiss()
                    } label: {
                        Text(currentGoal != nil ? "Update Goal" : "Set Goal")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .disabled(!isValid)
                }

                if currentGoal != nil {
                    Section {
                        Button(role: .destructive) {
                            showResetConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset Month")
                            }
                            .frame(maxWidth: .infinity)
                        }
                    } footer: {
                        Text("This will clear your goal and all sessions for \(currentMonthName).")
                    }
                }
            }
            .navigationTitle("Monthly Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let goal = currentGoal {
                    distanceText = String(format: "%.1f", goal.targetDistanceKm)
                }
                distanceFocused = true
            }
            .alert("Reset Month?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    onReset()
                    dismiss()
                }
            } message: {
                Text("This will delete your goal and all rowing sessions for \(currentMonthName). This cannot be undone.")
            }
        }
    }
}
