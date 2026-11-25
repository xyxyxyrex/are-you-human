#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION="4.7.2-stable"
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
TOOLS_DIR="$REPO_ROOT/.tools/godot"

resolve_godot() {
  if [[ -n "${GODOT_BIN:-}" && -x "${GODOT_BIN}" ]]; then
    echo "$GODOT_BIN"; return 0
  fi
  if [[ -x "$TOOLS_DIR/Godot.app/Contents/MacOS/Godot" ]]; then
    echo "$TOOLS_DIR/Godot.app/Contents/MacOS/Godot"; return 0
  fi
  for candidate in "$TOOLS_DIR"/Godot_v${GODOT_VERSION}_linux.*; do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"; return 0
    fi
  done
  if command -v godot >/dev/null 2>&1; then
    command -v godot; return 0
  fi
  if command -v godot4 >/dev/null 2>&1; then
    command -v godot4; return 0
  fi
  return 1
}

if ! GODOT_EXE="$(resolve_godot)"; then
  mkdir -p "$TOOLS_DIR"
  OS_NAME="$(uname -s)"
  ARCH_NAME="$(uname -m)"
  if [[ "$OS_NAME" == "Darwin" ]]; then
    ASSET="Godot_v${GODOT_VERSION}_macos.universal.zip"
  elif [[ "$OS_NAME" == "Linux" ]]; then
    if [[ "$ARCH_NAME" == "aarch64" || "$ARCH_NAME" == "arm64" ]]; then
      ASSET="Godot_v${GODOT_VERSION}_linux.arm64.zip"
    else
      ASSET="Godot_v${GODOT_VERSION}_linux.x86_64.zip"
    fi
  else
    echo "Unsupported OS for setup.sh: $OS_NAME (use setup.bat on Windows)" >&2
    exit 1
  fi

  URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${ASSET}"
  echo "Downloading Godot ${GODOT_VERSION} from ${URL} ..."
  curl -fL "$URL" -o "$TOOLS_DIR/$ASSET"
  unzip -qo "$TOOLS_DIR/$ASSET" -d "$TOOLS_DIR"
  rm -f "$TOOLS_DIR/$ASSET"
  chmod +x "$TOOLS_DIR"/Godot_v* 2>/dev/null || true
  GODOT_EXE="$(resolve_godot)"
fi

echo "Using Godot binary: $GODOT_EXE"
echo "Importing project assets..."
"$GODOT_EXE" --headless --path "$REPO_ROOT" --import

if [[ "${1:-}" != "--skip-verify" ]]; then
  "$REPO_ROOT/verify.sh"
fi

echo "Setup complete! Run ./run_game.sh to play or ./open_editor.sh to edit."
