import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: JournalStore
    @State private var settings: AppSettings = AppSettings.load()

    var body: some View {
        Form {
            Section("Keyboard Shortcut") {
                Text(settings.hotKeyDisplay)
                    .foregroundColor(.secondary)
                Text("Edit by re-recording in a future version — currently set in code as ⌥ Space.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Auto Archive Time") {
                Stepper("Hour: \(settings.autoArchiveHour)", value: $settings.autoArchiveHour, in: 0...23)
                Stepper("Minute: \(settings.autoArchiveMinute)", value: $settings.autoArchiveMinute, in: 0...59, step: 5)
            }

            Section("Apple Notes") {
                TextField("Folder", text: $settings.appleNotesFolder)
            }

            Section("Theme") {
                Picker("Theme", selection: $settings.theme) {
                    ForEach(AppSettings.Theme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section("Font") {
                TextField("Font name", text: $settings.fontName)
            }
        }
        .padding(20)
        .frame(width: 380)
        .onChange(of: settings) { newValue in
            newValue.save()
            store.settings = newValue
        }
    }
}
