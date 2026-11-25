#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
GODOT_VERSION="4.7.2-stable"
TOOLS_DIR="$REPO_ROOT/.tools/godot"

resolve_godot() {
  if [[ -n "${GODOT_BIN:-}" && -x "${GODOT_BIN}" ]]; then echo "$GODOT_BIN"; return 0; fi
  if [[ -x "$TOOLS_DIR/Godot.app/Contents/MacOS/Godot" ]]; then echo "$TOOLS_DIR/Godot.app/Contents/MacOS/Godot"; return 0; fi
  for c in "$TOOLS_DIR"/Godot_v${GODOT_VERSION}_linux.*; do
    if [[ -x "$c" ]]; then echo "$c"; return 0; fi
  done
  if command -v godot >/dev/null 2>&1; then command -v godot; return 0; fi
  if command -v godot4 >/dev/null 2>&1; then command -v godot4; return 0; fi
  return 1
}

if ! GODOT_EXE="$(resolve_godot)"; then
  "$REPO_ROOT/setup.sh" --skip-verify
  GODOT_EXE="$(resolve_godot)"
fi

exec "$GODOT_EXE" --path "$REPO_ROOT" "$@"
