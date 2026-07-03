import Foundation

enum DateFormatting {
    static func weekday(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    /// "July 1, 2026"
    static func longDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    /// "Wednesday, July 1, 2026" — used as the Apple Notes title
    static func longTitle(for date: Date) -> String {
        "\(weekday(for: date)), \(longDate(for: date))"
    }

    /// "July 3"
    static func shortDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }

    static func isSameDay(_ a: Date, _ b: Date) -> Bool {
        Calendar.current.isDate(a, inSameDayAs: b)
    }
}
