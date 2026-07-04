import SwiftUI

struct UpcomingBoxView: View {
    @EnvironmentObject var store: JournalStore
    @State private var hoveredItemID: UpcomingItem.ID?
    @State private var showingAddSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Upcoming")
                .font(.custom(store.settings.fontName, size: 16))
                .foregroundColor(.white.opacity(0.55))

            if store.upcomingItems.isEmpty {
                Text("Nothing on the horizon.")
                    .font(.custom(store.settings.fontName, size: 14))
                    .foregroundColor(.white.opacity(0.3))
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(store.upcomingItems) { item in
                        row(for: item)
                    }
                }
            }

            // Subtle, only-on-hover affordance — keeps the page clean otherwise.
            addDeadlineRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .notebookBox(seed: 1)
        .sheet(isPresented: $showingAddSheet) {
            AddUpcomingSheet { title, date in
                store.addUpcomingItem(title: title, dueDate: date)
            }
        }
    }

    private func row(for item: UpcomingItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.custom(store.settings.fontName, size: 15))
                    .foregroundColor(.white.opacity(item.isCompleted ? 0.4 : 0.9))
                    .strikethrough(item.isCompleted, color: .white.opacity(0.4))
                Text(item.remainingLabel)
                    .font(.custom(store.settings.fontName, size: 12))
                    .foregroundColor(.white.opacity(0.45))
            }

            Spacer()

            if hoveredItemID == item.id {
                HStack(spacing: 14) {
                    if !item.isCompleted {
                        Button {
                            store.addUpcomingToToday(item)
                        } label: {
                            Text("Add to Today's Page")
                                .font(.custom(store.settings.fontName, size: 12))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        store.removeUpcomingItem(item)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Remove this deadline")
                }
                .transition(.opacity)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredItemID = hovering ? item.id : nil
            }
        }
    }

    private var addDeadlineRow: some View {
        Button {
            showingAddSheet = true
        } label: {
            Text("+ Add a deadline")
                .font(.custom(store.settings.fontName, size: 12))
                .foregroundColor(.white.opacity(0.25))
        }
        .buttonStyle(.plain)
    }
}

private struct AddUpcomingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var date: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    let onAdd: (String, Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New deadline")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))

            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)

            DatePicker("Due", selection: $date, displayedComponents: .date)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Add") {
                    onAdd(title, date)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 320)
        .background(Color(white: 0.1))
    }
}
