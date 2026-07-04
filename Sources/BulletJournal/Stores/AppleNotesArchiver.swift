import Foundation
import AppKit

/// History is meant to live in Apple Notes, but that depends on macOS
/// automation permission being granted — if it isn't (or gets revoked),
/// this fails silently from the person's point of view. So archiving
/// always also writes a plain-text local backup that never depends on
/// permissions, in addition to attempting the Notes note.
enum AppleNotesArchiver {
    /// Returns true if the Apple Notes note was actually created.
    /// A local backup file is written either way — see `LocalArchive`.
    @discardableResult
    static func archive(date: Date, tasks: [TaskItem], folder: String) -> Bool {
        guard !tasks.isEmpty else { return true }

        let title = DateFormatting.longTitle(for: date)
        let lines = buildLines(title: title, tasks: tasks)

        LocalArchive.write(date: date, plainText: lines.joined(separator: "\n"))

        let htmlBody = lines.joined(separator: "<br>")
        let escapedBody = escape(htmlBody)
        let escapedFolder = escape(folder)

        let script = """
        tell application "Notes"
            if not (exists folder "\(escapedFolder)") then
                make new folder with properties {name:"\(escapedFolder)"}
            end if
            tell folder "\(escapedFolder)"
                make new note with properties {body:"\(escapedBody)"}
            end tell
        end tell
        """

        guard let appleScript = NSAppleScript(source: script) else { return false }
        var errorDict: NSDictionary?
        appleScript.executeAndReturnError(&errorDict)
        if let errorDict = errorDict {
            print("Apple Notes archive failed (local backup was still saved): \(errorDict)")
            return false
        }
        return true
    }

    private static func escape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    /// Shared content, independent of output format (HTML for Notes,
    /// plain text for the local backup file).
    private static func buildLines(title: String, tasks: [TaskItem]) -> [String] {
        var lines: [String] = [title, ""]

        let completed = tasks.filter { $0.state == .completed }
        let partial = tasks.filter { $0.state == .partiallyCompleted }
        let postponed = tasks.filter { $0.state == .postponed }
        let noLongerNeeded = tasks.filter { $0.state == .noLongerNeeded }
        // Tasks the day ended with no action taken on — these used to be
        // silently dropped from the archive entirely. Now they're kept,
        // exactly as written, so nothing from the page is ever lost.
        let leftOpen = tasks.filter { $0.state == .open }

        if !completed.isEmpty {
            lines.append("Completed")
            for t in completed { lines.append("✓ \(t.text)") }
            lines.append("")
        }

        if !partial.isEmpty {
            lines.append("Partially Completed")
            for t in partial {
                lines.append("◐ \(t.text)")
                if let p = t.progressNote, !p.isEmpty {
                    lines.append("Progress")
                    lines.append(p)
                }
                if let r = t.remainingNote, !r.isEmpty {
                    lines.append("Remaining")
                    lines.append(r)
                }
            }
            lines.append("")
        }

        if !postponed.isEmpty {
            lines.append("Postponed")
            for t in postponed {
                lines.append("→ \(t.text)")
                if let d = t.postponedToDate {
                    lines.append("Moved to")
                    lines.append(DateFormatting.shortDate(for: d))
                }
            }
            lines.append("")
        }

        if !noLongerNeeded.isEmpty {
            lines.append("No Longer Needed")
            for t in noLongerNeeded {
                lines.append("✕ \(t.text)")
                if let reason = t.noLongerNeededReason, !reason.isEmpty {
                    lines.append("Reason")
                    lines.append(reason)
                }
            }
            lines.append("")
        }

        if !leftOpen.isEmpty {
            lines.append("Not Completed")
            for t in leftOpen { lines.append("○ \(t.text)") }
        }

        while lines.last == "" { lines.removeLast() }
        return lines
    }
}

/// A plain-text-file safety net for daily archives, kept entirely outside
/// Apple Notes. Written on every rollover regardless of whether Notes
/// automation permission is granted, so a day's page is never truly lost.
enum LocalArchive {
    static var directoryURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("BulletJournal/Archive", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func write(date: Date, plainText: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let filename = "\(formatter.string(from: date)).txt"
        let url = directoryURL.appendingPathComponent(filename)
        try? plainText.write(to: url, atomically: true, encoding: .utf8)
    }
}
