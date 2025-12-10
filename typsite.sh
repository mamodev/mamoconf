#!/usr/bin/env bash
set -euo pipefail

APP_NAME="typsite"
REPO="Glomzzz/typsite"
PREFIX="${PREFIX:-/usr/local}"
BIN_DIR="$PREFIX/bin"
INSTALL_PATH="$BIN_DIR/$APP_NAME"

# Global temp dir; ensure cleanup only if it exists
TMPDIR_PATH=""
cleanup() {
  if [[ -n "${TMPDIR_PATH:-}" && -d "$TMPDIR_PATH" ]]; then
    rm -rf "$TMPDIR_PATH"
  fi
}
trap cleanup EXIT

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: required command not found: $1" >&2
    exit 1
  }
}

detect_asset_path() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os" in
    Linux)
      case "$arch" in
        x86_64|amd64) echo "typsite-x86_64-unknown-linux-gnu" ;;
        *)
          echo "Unsupported Linux arch: $arch" >&2
          return 1
          ;;
      esac
      ;;
    Darwin)
      case "$arch" in
        arm64|aarch64) echo "typsite-aarch64-apple-darwin" ;;
        *)
          echo "Unsupported macOS arch: $arch" >&2
          return 1
          ;;
      esac
      ;;
    *)
      echo "Unsupported OS: $os" >&2
      return 1
      ;;
  esac
}

fetch_latest_tag() {
  local latest_url tag
  latest_url="https://github.com/$REPO/releases/latest"
  if command -v curl >/dev/null 2>&1; then
    tag="$(curl -fsSL -o /dev/null -w '%{url_effective}' "$latest_url" \
      | awk -F/ '{print $NF}')"
  else
    tag="$(wget -q --max-redirect=0 -S "$latest_url" -O /dev/null 2>&1 \
      | awk '/^  Location: /{loc=$2} END{print loc}' \
      | awk -F/ '{print $NF}')"
  fi
  if [[ -z "$tag" ]]; then
    echo "Failed to resolve latest release tag." >&2
    exit 1
  fi
  echo "$tag"
}

install_typsite() {
  need_cmd mktemp
  need_cmd chmod
  need_cmd uname
  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    echo "Error: need curl or wget to download." >&2
    exit 1
  fi

  local asset_path rel_tag download_url tmpbin
  asset_path="$(detect_asset_path)"
  rel_tag="$(fetch_latest_tag)"
  download_url="https://github.com/$REPO/releases/download/$rel_tag/$asset_path"

  TMPDIR_PATH="$(mktemp -d)"
  tmpbin="$TMPDIR_PATH/$APP_NAME"

  echo "Downloading $APP_NAME ($asset_path) from $rel_tag ..."
  if command -v curl >/dev/null 2>&1; then
    curl -fL --proto '=https' --tlsv1.2 -o "$tmpbin" "$download_url"
  else
    wget -q -O "$tmpbin" "$download_url"
  fi
  chmod +x "$tmpbin"

  if [[ ! -d "$BIN_DIR" ]]; then
    echo "Creating directory: $BIN_DIR"
    if ! mkdir -p "$BIN_DIR" 2>/dev/null; then
      echo "Permission denied creating $BIN_DIR. Retrying with sudo..."
      sudo mkdir -p "$BIN_DIR"
    fi
  fi

  echo "Installing to: $INSTALL_PATH"
  if ! mv -f "$tmpbin" "$INSTALL_PATH" 2>/dev/null; then
    echo "Permission denied writing to $INSTALL_PATH. Retrying with sudo..."
    # Use sudo to install from the same temp path
    sudo mv -f "$tmpbin" "$INSTALL_PATH"
  fi

  # After moving, clear tmpbin path so cleanup won't error if sudo moved it
  if [[ ! -f "$tmpbin" ]]; then
    : # file moved; nothing to do
  fi

  # Quick verification (non-fatal)
  if ! "$INSTALL_PATH" --help >/dev/null 2>&1; then
    echo "Warning: installed binary did not execute cleanly. Verify manually." >&2
  fi

  echo "Installed $APP_NAME to $INSTALL_PATH"
  echo "Ensure $BIN_DIR is in your PATH."
}

uninstall_typsite() {
  local target="$INSTALL_PATH"
  if [[ -f "$target" ]]; then
    echo "Removing $target"
    if ! rm -f "$target" 2>/dev/null; then
      echo "Permission denied removing $target. Retrying with sudo..."
      sudo rm -f "$target"
    fi
    echo "Uninstalled $APP_NAME."
  else
    echo "$APP_NAME is not installed at $target."
  fi
}

main() {
  case "${1:-}" in
    uninstall)
      uninstall_typsite
      ;;
    "")
      install_typsite
      ;;
    *)
      echo "Usage: $0 [uninstall]" >&2
      exit 2
      ;;
  esac
}

main "$@"
