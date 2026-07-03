import Foundation
import Combine

/// The single source of truth for "today". The app deliberately keeps no
/// browsable history — once a day rolls over, its page is archived to
/// Apple Notes and forgotten here.
final class JournalStore: ObservableObject {
    @Published var todayTasks: [TaskItem] = []
    @Published var upcomingItems: [UpcomingItem] = []
    @Published var settings: AppSettings = AppSettings.load()

    private var currentDate: Date = Date()
    private var scheduledTasks: [String: [TaskItem]] = [:] // dayKey -> tasks to inject that day

    private let fileManager = FileManager.default
    private let directoryURL: URL
    private var todayURL: URL { directoryURL.appendingPathComponent("today.json") }
    private var scheduledURL: URL { directoryURL.appendingPathComponent("scheduled.json") }
    private var upcomingURL: URL { directoryURL.appendingPathComponent("upcoming.json") }

    init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        directoryURL = appSupport.appendingPathComponent("BulletJournal", isDirectory: true)
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        loadScheduled()
        loadUpcoming()
        loadTodayOrRollover()
    }

    // MARK: - Day key

    private func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Loading & rollover

    /// Call this whenever the popup opens (and periodically) so the page
    /// always reflects "today", archiving the previous day if needed.
    func checkForNewDay() {
        guard !DateFormatting.isSameDay(currentDate, Date()) else { return }
        rollover(to: Date())
    }

    private func loadTodayOrRollover() {
        if let page = readJSON(DayPage.self, from: todayURL) {
            currentDate = page.date
            if DateFormatting.isSameDay(page.date, Date()) {
                todayTasks = page.tasks
            } else {
                // App was closed across a day boundary — archive the stale page now.
                AppleNotesArchiver.archive(date: page.date, tasks: page.tasks, folder: settings.appleNotesFolder)
                rollover(to: Date())
            }
        } else {
            currentDate = Date()
            todayTasks = scheduledTasks[dayKey(for: Date())] ?? []
            scheduledTasks.removeValue(forKey: dayKey(for: Date()))
            persistToday()
            persistScheduled()
        }
    }

    private func rollover(to newDate: Date) {
        AppleNotesArchiver.archive(date: currentDate, tasks: todayTasks, folder: settings.appleNotesFolder)

        currentDate = newDate
        let key = dayKey(for: newDate)
        todayTasks = scheduledTasks[key] ?? []
        scheduledTasks.removeValue(forKey: key)

        persistToday()
        persistScheduled()
    }

    // MARK: - Today's Page actions

    func addTask(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        todayTasks.append(TaskItem(text: trimmed))
        persistToday()
    }

    func removeTask(_ task: TaskItem) {
        todayTasks.removeAll { $0.id == task.id }
        persistToday()
    }

    func updateText(_ task: TaskItem, to newText: String) {
        guard let index = todayTasks.firstIndex(where: { $0.id == task.id }) else { return }
        todayTasks[index].text = newText
        persistToday()
    }

    func toggleCompleted(_ task: TaskItem) {
        guard let index = todayTasks.firstIndex(where: { $0.id == task.id }) else { return }
        let newState: TaskBulletState = (todayTasks[index].state == .completed) ? .open : .completed
        todayTasks[index].state = newState
        persistToday()

        // Keep the originating deadline in sync — scratched, not deleted.
        if let linkedID = todayTasks[index].linkedUpcomingID,
           let upcomingIndex = upcomingItems.firstIndex(where: { $0.id == linkedID }) {
            upcomingItems[upcomingIndex].isCompleted = (newState == .completed)
            persistUpcoming()
        }
    }

    func markPartiallyCompleted(_ task: TaskItem, progress: String, remaining: String) {
        guard let index = todayTasks.firstIndex(where: { $0.id == task.id }) else { return }
        todayTasks[index].state = .partiallyCompleted
        todayTasks[index].progressNote = progress
        todayTasks[index].remainingNote = remaining
        persistToday()
    }

    func postpone(_ task: TaskItem, to date: Date) {
        guard let index = todayTasks.firstIndex(where: { $0.id == task.id }) else { return }
        todayTasks[index].state = .postponed
        todayTasks[index].postponedToDate = date

        var movedTask = todayTasks[index]
        movedTask.state = .open
        movedTask.postponedToDate = nil
        let key = dayKey(for: date)
        scheduledTasks[key, default: []].append(movedTask)

        persistToday()
        persistScheduled()
    }

    func markNoLongerNeeded(_ task: TaskItem, reason: String?) {
        guard let index = todayTasks.firstIndex(where: { $0.id == task.id }) else { return }
        todayTasks[index].state = .noLongerNeeded
        todayTasks[index].noLongerNeededReason = reason
        persistToday()
    }

    // MARK: - Upcoming

    func addUpcomingItem(title: String, dueDate: Date) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        upcomingItems.append(UpcomingItem(title: trimmed, dueDate: dueDate))
        upcomingItems.sort { $0.dueDate < $1.dueDate }
        persistUpcoming()
    }

    func removeUpcomingItem(_ item: UpcomingItem) {
        upcomingItems.removeAll { $0.id == item.id }
        persistUpcoming()
    }

    /// Hover action: only this turns an upcoming deadline into an actual task.
    func addUpcomingToToday(_ item: UpcomingItem) {
        todayTasks.append(TaskItem(text: item.title, linkedUpcomingID: item.id))
        persistToday()
    }

    // MARK: - Persistence

    private func persistToday() {
        writeJSON(DayPage(date: currentDate, tasks: todayTasks), to: todayURL)
    }

    private func persistScheduled() {
        writeJSON(scheduledTasks, to: scheduledURL)
    }

    private func persistUpcoming() {
        writeJSON(upcomingItems, to: upcomingURL)
    }

    private func loadScheduled() {
        scheduledTasks = readJSON([String: [TaskItem]].self, from: scheduledURL) ?? [:]
    }

    private func loadUpcoming() {
        upcomingItems = readJSON([UpcomingItem].self, from: upcomingURL) ?? []
    }

    private func readJSON<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func writeJSON<T: Encodable>(_ value: T, to url: URL) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
