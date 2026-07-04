import Foundation

// MARK: - Task

enum TaskBulletState: String, Codable {
    case open
    case completed
    case partiallyCompleted
    case postponed
    case noLongerNeeded
}

struct TaskItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var text: String
    var state: TaskBulletState = .open
    var createdDate: Date = Date()

    // Partially completed
    var progressNote: String?
    var remainingNote: String?

    // Postponed
    var postponedToDate: Date?

    // No longer needed
    var noLongerNeededReason: String?

    /// If this task was created via "Add to Today's Page" from an Upcoming
    /// deadline, this points back to that deadline so completing the task
    /// can mark the deadline as done without deleting it.
    var linkedUpcomingID: UUID?
}

// MARK: - Upcoming deadline

struct UpcomingItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var dueDate: Date

    /// True once the linked task has been completed. The deadline stays
    /// visible (scratched out) rather than disappearing — it's only
    /// removed by explicit deletion or once its own due date has fully passed.
    var isCompleted: Bool = false

    /// "Tomorrow", "2 days remaining", "Today", or "3 days ago"
    var remainingLabel: String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfDue = calendar.startOfDay(for: dueDate)
        let days = calendar.dateComponents([.day], from: startOfToday, to: startOfDue).day ?? 0

        switch days {
        case ..<0:
            let overdue = abs(days)
            return overdue == 1 ? "1 day ago" : "\(overdue) days ago"
        case 0:
            return "Today"
        case 1:
            return "Tomorrow"
        default:
            return "\(days) days remaining"
        }
    }
}

// MARK: - Day archive (what gets written to Apple Notes / persisted as "today")

struct DayPage: Codable {
    var date: Date
    var tasks: [TaskItem]
}
