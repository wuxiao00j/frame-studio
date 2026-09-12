#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
version=$(<VERSION)
if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  print -u2 'Commit the reviewed source before packaging / 请先提交已检查的源码'
  exit 1
fi
app="$PWD/dist/原境 Frame Studio.app"
[[ -d "$app" ]] || { print -u2 'Run scripts/build-app.sh first'; exit 1; }
release_dir="$PWD/dist/releases/v$version"
mkdir -p "$release_dir" "$PWD/.artifacts"
stage=$(mktemp -d "$PWD/.artifacts/release-stage.XXXXXX")
trap 'rm -rf "$stage"' EXIT
ditto "$app" "$stage/原境 Frame Studio.app"
mkdir -p "$stage/scripts" "$stage/config" "$stage/Examples"
cp README.md CHANGELOG.md THIRD_PARTY_NOTICES.md "$stage/"
ditto docs "$stage/docs"
ditto THIRD_PARTY_LICENSES "$stage/THIRD_PARTY_LICENSES"
cp scripts/configure-mcp.py scripts/mcp-smoke.py "$stage/scripts/"
cp config/codex.example.toml config/mcp.example.json "$stage/config/"
cp Examples/Demo.framestudio "$stage/Examples/"
ditto -c -k --sequesterRsrc "$stage" "$release_dir/FrameStudio-v$version-macOS-arm64.zip"
git archive --format=zip --prefix="frame-studio-$version/" --output="$release_dir/FrameStudio-v$version-source.zip" HEAD
python3 scripts/audit-release.py --tracked --archive "$release_dir/FrameStudio-v$version-macOS-arm64.zip" --archive "$release_dir/FrameStudio-v$version-source.zip"
python3 - "$release_dir" <<'PY'
import hashlib,pathlib,sys
root=pathlib.Path(sys.argv[1])
lines=[hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name for p in sorted(root.glob('*.zip'))]
(root/'SHA256SUMS.txt').write_text('\n'.join(lines)+'\n')
print(root)
PY
