import Foundation

struct AppSettings: Codable, Equatable {
    enum Theme: String, Codable, CaseIterable, Identifiable {
        case matteBlack = "Matte Black"
        case trueBlack = "True Black"
        var id: String { rawValue }
    }

    // Keyboard shortcut (stored as Carbon key code + modifier flags)
    var hotKeyDisplay: String = "⌥ Space"
    var hotKeyCode: UInt32 = 49      // kVK_Space
    var hotKeyModifiers: UInt32 = 2048 // optionKey (Carbon)

    // Auto-archive time — the moment the app rolls today's page into Apple Notes
    var autoArchiveHour: Int = 3
    var autoArchiveMinute: Int = 0

    // Apple Notes
    var appleNotesFolder: String = "Bullet Journal"

    // Appearance
    var theme: Theme = .matteBlack
    var fontName: String = "New York"

    static let defaultsKey = "com.bulletjournal.settings.v1"

    static func load() -> AppSettings {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            return decoded
        }
        return AppSettings()
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}
