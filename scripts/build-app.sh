#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
swift build -c release
destination="$PWD/dist/原境 Frame Studio.app"
app="$PWD/dist/.FrameStudio-staging.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp .build/release/FrameStudio "$app/Contents/MacOS/FrameStudio"
cp .build/release/frame-studio-mcp "$app/Contents/MacOS/frame-studio-mcp"
ditto Sources/StudioCore/ExportTemplates "$app/Contents/Resources/ExportTemplates"
strip -S "$app/Contents/MacOS/FrameStudio"
strip -S "$app/Contents/MacOS/frame-studio-mcp"
cp Resources/Info.plist "$app/Contents/Info.plist"
if [[ -f Resources/AppIcon.icns ]]; then
  cp Resources/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
fi
codesign --force --deep --sign - "$app"
if [[ -d "$destination" ]]; then
  mkdir -p "$PWD/.artifacts"
  mv "$destination" "$PWD/.artifacts/PreviousBuild-$(date +%s).app"
fi
mv "$app" "$destination"
app="$destination"
ditto -c -k --sequesterRsrc --keepParent "$app" "$PWD/dist/FrameStudio-macOS.zip"
printf '%s\n' "$app"
