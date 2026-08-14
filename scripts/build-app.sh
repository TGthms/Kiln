#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
cd "$ROOT"
python3 scripts/generate_localizations.py
python3 scripts/generate_xcodeproj.py
DEST="$ROOT/build"
mkdir -p "$DEST"
xcodebuild \
  -project Kiln.xcodeproj \
  -scheme Kiln \
  -configuration Release \
  -derivedDataPath "$DEST/DerivedData" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_ALLOWED=YES \
  CODE_SIGNING_REQUIRED=NO \
  build
APP=$(find "$DEST/DerivedData/Build/Products" -name 'Kiln.app' -maxdepth 4 | head -n 1)
if [[ -z "$APP" ]]; then
  echo "Kiln.app not found" >&2
  exit 1
fi
rm -rf "$DEST/Kiln.app"
cp -R "$APP" "$DEST/Kiln.app"
# Drop debug-only dylibs if present so the bundle looks like a shipped app.
setopt NULL_GLOB
rm -f "$DEST/Kiln.app/Contents/MacOS/"*.debug.dylib "$DEST/Kiln.app/Contents/MacOS/__preview.dylib"
unsetopt NULL_GLOB
chmod +x "$DEST/Kiln.app/Contents/MacOS/Kiln"
echo "Built $DEST/Kiln.app"
