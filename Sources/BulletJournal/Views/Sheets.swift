import SwiftUI

struct PartialCompletionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let task: TaskItem
    let onSave: (String, String) -> Void

    @State private var progress: String = ""
    @State private var remaining: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(task.text)
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            Text("What progress did you make?")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            TextField("e.g. Finished Chapters 1–3", text: $progress)
                .textFieldStyle(.roundedBorder)

            Text("What's remaining?")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            TextField("e.g. Chapter 4", text: $remaining)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    onSave(progress, remaining)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 340)
        .background(Color(white: 0.1))
    }
}

struct PostponeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let task: TaskItem
    let onSave: (Date) -> Void

    @State private var date: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(task.text)
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            Text("Move this to:")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))

            DatePicker("", selection: $date, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Postpone") {
                    onSave(date)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 320)
        .background(Color(white: 0.1))
    }
}

struct NoLongerNeededSheet: View {
    @Environment(\.dismiss) private var dismiss
    let task: TaskItem
    let onSave: (String?) -> Void

    @State private var reason: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(task.text)
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            Text("This isn't a failure — just no longer needed.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))

            Text("Why? (optional)")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
            TextField("e.g. Trip cancelled", text: $reason)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("Skip") {
                    onSave(nil)
                    dismiss()
                }
                Button("Save") {
                    onSave(reason.isEmpty ? nil : reason)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 340)
        .background(Color(white: 0.1))
    }
}
