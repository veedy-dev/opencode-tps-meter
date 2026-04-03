#!/usr/bin/env bash
set -euo pipefail

INSTALL_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/opencode-tps-meter"
BIN_DIR="$HOME/.local/bin"
WRAPPER="$BIN_DIR/opencode"
STOCK="$BIN_DIR/opencode-stock"

if [ -e "$STOCK" ]; then
  mv "$STOCK" "$WRAPPER"
else
  rm -f "$WRAPPER"
fi

rm -rf "$INSTALL_ROOT"

echo "Removed OpenCode TPS Meter."
