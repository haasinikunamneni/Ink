#!/bin/bash
# Builds BulletJournal into a real, double-clickable .app bundle —
# no Xcode required. Run from the project root:
#
#   ./build_app.sh
#
# Then drag the resulting BulletJournal.app into /Applications.

set -e

BUNDLE_DIR="BulletJournal.app"
EXECUTABLE_NAME="BulletJournal"

echo "Building release binary…"
swift build -c release

echo "Assembling ${BUNDLE_DIR}…"
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR/Contents/MacOS"

cp ".build/release/${EXECUTABLE_NAME}" "$BUNDLE_DIR/Contents/MacOS/${EXECUTABLE_NAME}"
cp "Resources/Info-AppBundle.plist" "$BUNDLE_DIR/Contents/Info.plist"

echo "Ad-hoc signing (keeps permission prompts consistent across rebuilds)…"
codesign --force --deep --sign - "$BUNDLE_DIR"

echo ""
echo "Done — ${BUNDLE_DIR} is ready."
echo "Drag it into /Applications, then double-click to launch it."
echo "Press ⌥ Space to summon the panel."
echo ""
echo "To have it start automatically at login: System Settings → General →"
echo "Login Items → add ${BUNDLE_DIR}."
