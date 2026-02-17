import SwiftUI

struct AddSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date.now
    @State private var hours = 0
    @State private var minutes = 30
    @State private var distanceText = ""
    @FocusState private var distanceFocused: Bool

    let onSave: (Date, Int, Double) -> Void

    private var isValid: Bool {
        guard let distance = Double(distanceText), distance > 0 else { return false }
        return hours > 0 || minutes > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    DatePicker("Session Date", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }

                Section("Duration") {
                    HStack(spacing: 0) {
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<13, id: \.self) { h in
                                Text("\(h)h").tag(h)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60, id: \.self) { m in
                                Text("\(m)m").tag(m)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 120)
                }

                Section("Distance") {
                    HStack {
                        TextField("0.0", text: $distanceText)
                            .keyboardType(.decimalPad)
                            .focused($distanceFocused)
                            .font(.title3)
                        Text("km")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let distance = Double(distanceText) else { return }
                        let totalSeconds = hours * 3600 + minutes * 60
                        onSave(date, totalSeconds, distance)
                        dismiss()
                    }
                    .disabled(!isValid)
                    .bold()
                }
            }
            .onAppear {
                distanceFocused = true
            }
        }
    }
}
