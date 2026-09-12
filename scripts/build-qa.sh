#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
app="$PWD/.artifacts/FrameStudio QA.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp .build/debug/FrameStudio "$app/Contents/MacOS/FrameStudio"
ditto Sources/StudioCore/ExportTemplates "$app/Contents/Resources/ExportTemplates"
cp Resources/Info.plist "$app/Contents/Info.plist"
cp Resources/AppIcon.icns "$app/Contents/Resources/"
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier local.barry.FrameStudioQA' "$app/Contents/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :CFBundleName FrameStudio QA' "$app/Contents/Info.plist"
codesign --force --deep --sign - "$app"
open "$app" --args --project "/tmp/FrameStudio-1.2-QA.framestudio"
