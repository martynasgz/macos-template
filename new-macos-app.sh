#!/usr/bin/env bash
# Scaffold a new macOS SwiftUI app from this template, with XcodeGen + xcode-build-server
# wired up for VS Code intellisense.
#
# Usage: ./new-macos-app.sh <ProjectName> [target-directory]
#   target-directory is where the project gets scaffolded directly (created if
#   needed, must be empty). Pass "." to scaffold into the current directory.
#   Defaults to a new sibling folder next to this template, named <ProjectName>.

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <ProjectName> [target-directory]" >&2
  exit 1
fi

NAME="$1"

if [[ ! "$NAME" =~ ^[A-Za-z][A-Za-z0-9]*$ ]]; then
  echo "Error: '$NAME' isn't a valid Swift type name (letters/digits, must start with a letter, no spaces)." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_INPUT="${2:-$SCRIPT_DIR/../$NAME}"

mkdir -p "$DEST_INPUT"
DEST="$(cd "$DEST_INPUT" && pwd)"

if [ -n "$(ls -A "$DEST" 2>/dev/null)" ]; then
  echo "Error: $DEST already exists and is not empty" >&2
  exit 1
fi

for tool in xcodegen xcode-build-server; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Error: '$tool' not found in PATH. Install with: brew install $tool" >&2
    exit 1
  fi
done

echo "Scaffolding $NAME in $DEST ..."
cp -R "$SCRIPT_DIR/template/." "$DEST/"

mv "$DEST/Sources/__NAME__App.swift" "$DEST/Sources/${NAME}App.swift"
sed -i '' "s/__NAME__/${NAME}/g" \
  "$DEST/project.yml" \
  "$DEST/Sources/${NAME}App.swift" \
  "$DEST/Sources/ContentView.swift" \
  "$DEST/.vscode/tasks.json" \
  "$DEST/.vscode/launch.json"

cd "$DEST"
xcodegen generate
xcode-build-server config -scheme "$NAME" -project "${NAME}.xcodeproj" >/dev/null

git init -q
git add -A
git commit -q -m "Initial scaffold for $NAME"

echo ""
echo "Done. Next steps:"
echo "  code \"$DEST\""
echo "  (install the recommended 'Swift' and 'CodeLLDB' extensions when VS Code prompts you)"
echo "  Cmd+Shift+B to build, F5 to build & debug, or run task 'Run $NAME' to just launch it"
