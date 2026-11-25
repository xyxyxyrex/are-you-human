#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION="4.7.2-stable"
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
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

if command -v python3 >/dev/null 2>&1; then
  echo "=== 1. Project Resource & Scene Integrity Check ==="
  python3 "$REPO_ROOT/.agents/skills/godot-nodes-scenes/scripts/check_godot_project.py" "$REPO_ROOT"
fi

echo "=== 2. Strict GDScript Compile Check ==="
"$GODOT_EXE" --headless --path "$REPO_ROOT" --script "$REPO_ROOT/.agents/skills/godot-gdscript/assets/check_scripts_compile.gd"

echo "=== 3. Audio Bus Wiring Check ==="
"$GODOT_EXE" --headless --path "$REPO_ROOT" --script "$REPO_ROOT/.agents/skills/godot-audio/assets/check_audio_buses.gd"

echo "=== 4. End-to-End Campaign & Layout Test Suite ==="
"$GODOT_EXE" --headless --path "$REPO_ROOT" --scene "res://tests/test_runner.tscn"

echo "ALL VERIFICATION CHECKS PASSED!"
