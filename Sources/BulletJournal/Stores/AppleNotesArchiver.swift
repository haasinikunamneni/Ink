import Foundation
import AppKit

/// History lives in Apple Notes, never in the app. This builds a single
/// formatted note per day and files it into the configured Notes folder.
enum AppleNotesArchiver {
    static func archive(date: Date, tasks: [TaskItem], folder: String) {
        guard !tasks.isEmpty else { return }

        let title = DateFormatting.longTitle(for: date)
        let body = buildBody(title: title, tasks: tasks)
        let escapedBody = escape(body)
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

        guard let appleScript = NSAppleScript(source: script) else { return }
        var errorDict: NSDictionary?
        appleScript.executeAndReturnError(&errorDict)
        if let errorDict = errorDict {
            print("Apple Notes archive failed: \(errorDict)")
        }
    }

    private static func escape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    /// Notes' "body" property accepts a small HTML subset — <b> and <br> are
    /// enough to reproduce the bullet-journal-page formatting.
    private static func buildBody(title: String, tasks: [TaskItem]) -> String {
        var lines: [String] = ["<b>\(title)</b>", ""]

        let completed = tasks.filter { $0.state == .completed }
        let partial = tasks.filter { $0.state == .partiallyCompleted }
        let postponed = tasks.filter { $0.state == .postponed }
        let noLongerNeeded = tasks.filter { $0.state == .noLongerNeeded }

        if !completed.isEmpty {
            lines.append("<b>Completed</b>")
            for t in completed { lines.append("✓ \(t.text)") }
            lines.append("")
        }

        if !partial.isEmpty {
            lines.append("<b>Partially Completed</b>")
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
            lines.append("<b>Postponed</b>")
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
            lines.append("<b>No Longer Needed</b>")
            for t in noLongerNeeded {
                lines.append("✕ \(t.text)")
                if let reason = t.noLongerNeededReason, !reason.isEmpty {
                    lines.append("Reason")
                    lines.append(reason)
                }
            }
        }

        while lines.last == "" { lines.removeLast() }
        return lines.joined(separator: "<br>")
    }
}
