#!/usr/bin/env bash
set -euo pipefail

REPO_RAW_BASE="https://raw.githubusercontent.com/guard22/opencode-tps-meter/main"
UPSTREAM_REPO="https://github.com/anomalyco/opencode.git"
INSTALL_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/opencode-tps-meter"
RELEASES_DIR="$INSTALL_ROOT/releases"
CURRENT_LINK="$INSTALL_ROOT/current"
BIN_DIR="$HOME/.local/bin"
WRAPPER="$BIN_DIR/opencode"
STOCK="$BIN_DIR/opencode-stock"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_LOCAL="$SCRIPT_DIR/manifest.sh"
MANIFEST_DOWNLOADED="$INSTALL_ROOT/manifest.sh"
TMP_DIR=""

cleanup() {
  if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

fail() {
  echo "Error: $*" >&2
  exit 1
}

load_manifest() {
  if [ -f "$MANIFEST_LOCAL" ]; then
    # shellcheck disable=SC1090
    . "$MANIFEST_LOCAL"
    return
  fi

  mkdir -p "$INSTALL_ROOT"
  curl -fsSL "$REPO_RAW_BASE/manifest.sh" -o "$MANIFEST_DOWNLOADED"
  # shellcheck disable=SC1090
  . "$MANIFEST_DOWNLOADED"
}

need git
need curl
need bun

load_manifest

REQUESTED_VERSION="${OPENCODE_TPS_VERSION:-$LATEST_SUPPORTED}"
is_supported_version "$REQUESTED_VERSION" || fail \
  "Unsupported OpenCode version '$REQUESTED_VERSION'. Supported versions: $(print_supported_versions | paste -sd ', ' -)"

UPSTREAM_TAG="$(resolve_upstream_tag "$REQUESTED_VERSION")"
PATCH_RELATIVE_PATH="$(resolve_patch_path "$REQUESTED_VERSION")"
PATCH_URL="$REPO_RAW_BASE/$PATCH_RELATIVE_PATH"
PATCH_LOCAL="$SCRIPT_DIR/$PATCH_RELATIVE_PATH"
RELEASE_DIR="$RELEASES_DIR/$REQUESTED_VERSION"
PATCH_FILE="$INSTALL_ROOT/opencode-$REQUESTED_VERSION.patch"
EXISTING_OPENCODE="$(command -v opencode || true)"
BUN_BIN="$(command -v bun)"

mkdir -p "$INSTALL_ROOT" "$RELEASES_DIR" "$BIN_DIR"
TMP_DIR="$(mktemp -d "$INSTALL_ROOT/.install.XXXXXX")"
TMP_SRC="$TMP_DIR/opencode-src"

if [ -f "$PATCH_LOCAL" ]; then
  cp "$PATCH_LOCAL" "$PATCH_FILE"
else
  curl -fsSL "$PATCH_URL" -o "$PATCH_FILE"
fi

git clone --depth 1 --branch "$UPSTREAM_TAG" "$UPSTREAM_REPO" "$TMP_SRC"
git -C "$TMP_SRC" apply --check "$PATCH_FILE" || fail \
  "Patch does not apply cleanly to $UPSTREAM_TAG. This version is not safe to install with the current patch."
git -C "$TMP_SRC" apply "$PATCH_FILE"
(cd "$TMP_SRC" && bun install --frozen-lockfile)

if [ -d "$RELEASE_DIR" ]; then
  rm -rf "$RELEASE_DIR"
fi
mv "$TMP_SRC" "$RELEASE_DIR"
ln -sfn "$RELEASE_DIR" "$CURRENT_LINK"

if [ -e "$WRAPPER" ] && [ ! -e "$STOCK" ]; then
  cp "$WRAPPER" "$STOCK"
elif [ ! -e "$STOCK" ] && [ -n "$EXISTING_OPENCODE" ] && [ "$EXISTING_OPENCODE" != "$WRAPPER" ]; then
  cat > "$STOCK" <<'STOCKEOF'
#!/bin/zsh
exec "__EXISTING_OPENCODE__" "$@"
STOCKEOF
  perl -0pi -e 's|__EXISTING_OPENCODE__|'"$EXISTING_OPENCODE"'|g' "$STOCK"
  chmod +x "$STOCK"
fi

cat > "$WRAPPER" <<'WRAPEOF'
#!/bin/zsh
set -euo pipefail
SOURCE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/opencode-tps-meter/current/packages/opencode"
FALLBACK="$HOME/.local/bin/opencode-stock"
if [ ! -d "$SOURCE_DIR" ]; then
  if [ -x "$FALLBACK" ]; then
    exec "$FALLBACK" "$@"
  fi
  echo "opencode-tps-meter source install is missing: $SOURCE_DIR" >&2
  exit 1
fi
ORIG_PWD="${PWD:-$(pwd)}"
export OPENCODE_LAUNCH_CWD="$ORIG_PWD"
exec "__BUN_BIN__" --cwd "$SOURCE_DIR" --conditions=browser ./src/index.ts "$@"
WRAPEOF
perl -0pi -e 's|__BUN_BIN__|'"$BUN_BIN"'|g' "$WRAPPER"
chmod +x "$WRAPPER"

echo "Installed OpenCode TPS Meter for OpenCode $REQUESTED_VERSION."
echo "Run: opencode"
echo "Fallback: opencode-stock"
