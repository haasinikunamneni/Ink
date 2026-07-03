import SwiftUI

struct TodayPageView: View {
    @EnvironmentObject var store: JournalStore
    var isFocused: FocusState<Bool>.Binding

    @State private var newTaskText: String = ""
    @State private var partialTarget: TaskItem?
    @State private var postponeTarget: TaskItem?
    @State private var noLongerNeededTarget: TaskItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Today's Page")
                .font(.custom(store.settings.fontName, size: 16))
                .foregroundColor(.white.opacity(0.55))

            VStack(alignment: .leading, spacing: 14) {
                ForEach(store.todayTasks) { task in
                    if task.state != .postponed && task.state != .noLongerNeeded {
                        TaskRowView(
                            task: task,
                            onToggleComplete: { store.toggleCompleted(task) },
                            onRequestPartial: { partialTarget = task },
                            onRequestPostpone: { postponeTarget = task },
                            onRequestNoLongerNeeded: { noLongerNeededTarget = task }
                        )
                        .environmentObject(store)
                    }
                }

                TextField("Write what's on your mind for today…", text: $newTaskText)
                    .textFieldStyle(.plain)
                    .font(.custom(store.settings.fontName, size: 15))
                    .foregroundColor(.white.opacity(0.92))
                    .focused(isFocused)
                    .onSubmit {
                        store.addTask(newTaskText)
                        newTaskText = ""
                    }
            }

        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .notebookBox(seed: 2)
        .sheet(item: $partialTarget) { task in
            PartialCompletionSheet(task: task) { progress, remaining in
                store.markPartiallyCompleted(task, progress: progress, remaining: remaining)
            }
        }
        .sheet(item: $postponeTarget) { task in
            PostponeSheet(task: task) { date in
                store.postpone(task, to: date)
            }
        }
        .sheet(item: $noLongerNeededTarget) { task in
            NoLongerNeededSheet(task: task) { reason in
                store.markNoLongerNeeded(task, reason: reason)
            }
        }
    }
}

struct TaskRowView: View {
    @EnvironmentObject var store: JournalStore
    let task: TaskItem
    @State private var isHovering = false

    let onToggleComplete: () -> Void
    let onRequestPartial: () -> Void
    let onRequestPostpone: () -> Void
    let onRequestNoLongerNeeded: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(bullet)
                .font(.custom(store.settings.fontName, size: 15))
                .foregroundColor(.white.opacity(task.state == .completed ? 0.4 : 0.85))
                .onTapGesture { onToggleComplete() }

            Text(task.text)
                .font(.custom(store.settings.fontName, size: 15))
                .foregroundColor(.white.opacity(task.state == .completed ? 0.35 : 0.92))
                .strikethrough(task.state == .completed, color: .white.opacity(0.3))

            Spacer()

            if isHovering {
                HStack(spacing: 14) {
                    actionButton(symbol: "checkmark", action: onToggleComplete)
                    actionButton(symbol: "circle.lefthalf.filled", action: onRequestPartial)
                    actionButton(symbol: "arrow.right", action: onRequestPostpone)
                    actionButton(symbol: "xmark", action: onRequestNoLongerNeeded)
                }
                .transition(.opacity)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .animation(.easeInOut(duration: 0.2), value: task.state)
    }

    private var bullet: String {
        task.state == .completed ? "✓" : "○"
    }

    private func actionButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.65))
        }
        .buttonStyle(.plain)
    }
}
