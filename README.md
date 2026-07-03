# INK — macOS App (Source)
A To-do application i made as a personal project to cater to my minimal needs
A floating, Spotlight-style bullet journal for macOS. Matte black page,
two hand-drawn boxes (Upcoming + Today's Page), nothing else. History
lives entirely in Apple Notes — the app never becomes a dashboard.

This is delivered as a **Swift Package** so you can build and run it
straight from Terminal — no Xcode required for day-to-day use. (Xcode
is still useful if you later want a proper signed `.app` with a custom
icon and Dock-hiding behavior baked into a bundle — see "Going further"
at the bottom.)

## Quickest path: run it from Terminal

Requires Xcode Command Line Tools (you almost certainly already have
these if you have `swift` on your Mac — check with `swift --version`;
if that fails, run `xcode-select --install`).

```bash
cd BulletJournal
swift run
```

The first build takes 10–30 seconds. After that, the app is running —
press **⌥ Space** (Option-Space) anywhere on your Mac to summon the
floating panel, same as Spotlight. `Ctrl-C` in Terminal quits it.

Because this is an unbundled executable (not a `.app`), two things
behave slightly differently than the final polished version:

- **It'll show a generic icon briefly in the Dock/app-switcher** while
  running, since the `LSUIElement` (hide from Dock) setting only takes
  effect inside a real `.app` bundle — `swift run` doesn't produce one.
- **The first time you postpone or complete a task**, macOS will ask
  permission for "BulletJournal" (or your terminal) to control Notes —
  approve it, or archiving to Apple Notes won't happen.

Both are cosmetic — all the actual app behavior (panel, boxes, hover
actions, task states, Apple Notes archiving) works identically.

To rebuild after editing any `.swift` file, just run `swift run` again.

## Install it as a real app (no more `swift run` every time)

Once you're happy with it, build a proper `.app` you can launch from
Spotlight or by double-clicking — no Xcode needed:

```bash
cd BulletJournal
./build_app.sh
```

This builds a release binary and wraps it in `BulletJournal.app` with
the correct `Info.plist` (accessory app, no Dock icon) and an ad-hoc
code signature so macOS will run it locally. Then:

```bash
mv "BulletJournal.app" /Applications/
```

Now you can launch it from Spotlight (⌘ Space, type "Bullet Journal"),
or just leave it running in the background permanently by adding it to
**System Settings → General → Login Items**, so it's always available
on ⌥ Space after every restart — exactly like a real launcher app.

Re-run `./build_app.sh` any time you change the source and want to
update the installed app.

## Going further: build a real `.app` with Xcode

If you want a proper double-clickable `.app` (custom Dock icon if you
add one, no Terminal window needed to launch it, no permission-prompt
quirks), wrap the same source in an Xcode project:

## 1. Create the Xcode project

1. Open Xcode → **File → New → Project**.
2. Choose **macOS → App**, click Next.
3. Product Name: `BulletJournal`. Interface: **SwiftUI**. Language: **Swift**.
4. Uncheck "Use Core Data" / "Include Tests" (not needed). Create it
   somewhere on disk.

## 2. Replace the generated files with these

Xcode will have created `BulletJournalApp.swift` and `ContentView.swift`
for you — **delete both** from the project (Move to Trash), then drag
the folders from `Sources/BulletJournal/` in this delivery (`App`,
`Models`, `Stores`, `Views`, `Utilities`) into the Xcode project
navigator, checking "Copy items if needed" and adding them to the
`BulletJournal` target.

Resulting structure:

```
Sources/BulletJournal/
  App/
    BulletJournalApp.swift     — @main, AppDelegate, panel show/hide, hotkey
    FloatingPanel.swift        — borderless floating NSPanel (Spotlight-style)
  Models/
    Models.swift                — TaskItem, UpcomingItem, DayPage
    AppSettings.swift           — persisted settings
  Stores/
    JournalStore.swift          — today's page, day rollover, persistence
    AppleNotesArchiver.swift    — writes the formatted note via AppleScript
  Views/
    ContentView.swift           — date header + the two boxes
    UpcomingBoxView.swift       — deadlines, hover "Add to Today's Page"
    TodayPageView.swift         — the editable page + task row + hover actions
    Sheets.swift                — partial-completion / postpone / no-longer-needed
    SettingsView.swift          — the minimal settings form
  Utilities/
    HandDrawnBox.swift          — the wobbly-rounded-rect notebook box look
    DateFormatting.swift
    GlobalHotKey.swift           — Carbon-based system-wide shortcut
```

## 3. Project settings

- **Signing & Capabilities**: leave App Sandbox **off**. The app talks to
  Notes.app via AppleScript (Apple Events) — that's simplest unsandboxed.
  (It's possible to sandbox this with the
  `com.apple.security.automation.apple-events` entitlement plus a
  temporary exception for `com.apple.Notes`, but that adds friction
  you don't need for a personal-use app.)
- **Info.plist**: use `Resources/Info.plist` from this delivery (or copy
  its two custom keys — `LSUIElement = YES` and
  `NSAppleEventsUsageDescription` — into the one Xcode generated).
- **Deployment target**: macOS 13 or later (uses `NSHostingView` layer
  animation APIs and modern SwiftUI `.focused`/`.sheet(item:)`).
- **Frameworks**: `import Carbon` works without manually linking
  anything extra — it's a system framework Swift resolves automatically.

## 4. Build & run

⌘R. The app has no Dock icon and no menu bar item by design — it's
running in the background. Press **⌥ Space** (Option-Space) to summon
the panel, exactly like Spotlight. Escape, or clicking away, dismisses it.

> First time you postpone/complete a task with content, macOS will ask
> for permission to let "BulletJournal" control "Notes" — approve it,
> or archiving silently won't happen.

## Notes on a few judgment calls I made

The brief is very precise about what *not* to build, which I followed
literally — but a couple of small mechanics weren't fully specified, so
here's what I assumed:

- **Adding Upcoming items**: the spec shows the Upcoming box populated
  with deadlines but never says how they get there (it's explicitly not
  a task list). I added one small, low-emphasis "+ Add a deadline"
  affordance at the bottom of the box — same restrained visual weight
  as everything else — that opens a tiny two-field sheet (title + date).
- **Keyboard shortcut customization**: the settings list calls for a
  "Keyboard shortcut" setting. Recording a custom shortcut live in a
  settings UI is a non-trivial separate component (key-capture view) —
  I wired the underlying setting and hotkey registration to be fully
  config-driven, but shipped the picker UI as a placeholder field you
  can wire up to a recorder control (or change the default in
  `AppSettings.swift`) rather than guessing at a UI you didn't ask for.
- **Font setting**: stored as a plain font name string (e.g. "New
  York") rather than a font picker, kept deliberately simple per the
  "settings should be minimal" instruction.

Everything else — the two-box-only layout, no dividers, hover-reveal
task actions, four task states, the partial-completion/postpone/no-
longer-needed flows, the Apple-Notes-only history model, the open
animation, and the matte-black hand-drawn aesthetic — is built as
specified.
