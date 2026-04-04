#!/usr/bin/env bash

LATEST_SUPPORTED="1.3.14"
SUPPORTED_VERSIONS=("1.3.14" "1.3.13")

resolve_upstream_tag() {
  case "$1" in
    1.3.14) printf '%s\n' 'v1.3.14' ;;
    1.3.13) printf '%s\n' 'v1.3.13' ;;
    *) return 1 ;;
  esac
}

resolve_patch_path() {
  case "$1" in
    1.3.14) printf '%s\n' 'patches/opencode-1.3.14-tps.patch' ;;
    1.3.13) printf '%s\n' 'patches/opencode-1.3.13-tps.patch' ;;
    *) return 1 ;;
  esac
}

is_supported_version() {
  resolve_upstream_tag "$1" >/dev/null 2>&1
}

print_supported_versions() {
  printf '%s\n' "${SUPPORTED_VERSIONS[@]}"
}
