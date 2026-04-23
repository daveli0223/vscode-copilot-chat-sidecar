#!/usr/bin/env bash
# reinstall-sidecar.sh
# Build the sidecar VSIX and reinstall it into VS Code / VS Code Insiders.
# Optionally watches for source file changes and reinstalls automatically.
#
# Usage:
#   ./script/reinstall-sidecar.sh          # build + install once
#   ./script/reinstall-sidecar.sh --watch  # build + install, then re-run on every src change

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VSIX_PATH="$REPO_ROOT/copilot-chat-sidecar.vsix"
WATCH_MODE=false

for arg in "$@"; do
  [[ "$arg" == "--watch" ]] && WATCH_MODE=true
done

# Resolve VS Code CLI (prefers Insiders)
if command -v code-insiders &>/dev/null; then
  CODE_CLI="code-insiders"
elif [[ -x "/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin/code" ]]; then
  CODE_CLI="/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin/code"
elif [[ -x "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]]; then
  CODE_CLI="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
elif command -v code &>/dev/null; then
  CODE_CLI="code"
else
  echo "ERROR: VS Code CLI not found. Install VS Code or add 'code' to PATH." >&2
  exit 1
fi

echo "Using VS Code CLI: $CODE_CLI"

build_and_install() {
  echo ""
  echo "=== $(date '+%H:%M:%S') Building VSIX ==="
  cd "$REPO_ROOT"
  npm run compile
  npx vsce package --out "$VSIX_PATH" --allow-package-secrets sendgrid

  echo "=== $(date '+%H:%M:%S') Installing VSIX ==="
  "$CODE_CLI" --install-extension "$VSIX_PATH" --force
  echo "=== $(date '+%H:%M:%S') Done — reload VS Code window to activate the new version ==="
}

build_and_install

if [[ "$WATCH_MODE" == true ]]; then
  # Check for fswatch (macOS); fall back to a polling loop if not available.
  if command -v fswatch &>/dev/null; then
    echo ""
    echo "Watching src/, pwa/ for changes (fswatch). Ctrl+C to stop."
    fswatch -o "$REPO_ROOT/src" "$REPO_ROOT/pwa" | while read -r _; do
      build_and_install
    done
  else
    echo ""
    echo "fswatch not found — using 5-second polling loop."
    echo "Install fswatch for faster detection: brew install fswatch"
    echo "Watching src/, pwa/ for changes. Ctrl+C to stop."
    LAST_HASH=""
    while true; do
      CURRENT_HASH=$(find "$REPO_ROOT/src" "$REPO_ROOT/pwa" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.css" \) -newer "$VSIX_PATH" 2>/dev/null | sort | md5)
      if [[ "$CURRENT_HASH" != "$LAST_HASH" && -n "$CURRENT_HASH" ]]; then
        LAST_HASH="$CURRENT_HASH"
        build_and_install
      fi
      sleep 5
    done
  fi
fi
