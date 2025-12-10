#!/usr/bin/env bash
set -euo pipefail

FONT_NAME="0xProto"
ZIP_FILE="${FONT_NAME}.zip"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${ZIP_FILE}"
INSTALL_DIR="${HOME}/.local/share/fonts"

echo "→ Installing ${FONT_NAME} Nerd Font..."

# Detect and create proper font dir
mkdir -p "${INSTALL_DIR}"

# Download
echo "→ Downloading font..."
wget -q "${FONT_URL}" -O "${ZIP_FILE}"

# Unzip
echo "→ Extracting..."
unzip -q "${ZIP_FILE}" -d "${INSTALL_DIR}"

# Refresh font cache
if command -v fc-cache &>/dev/null; then
  echo "→ Refreshing font cache (Linux)..."
  fc-cache -fv >/dev/null
elif [[ "$OSTYPE" == "darwin"* ]]; then
  echo "→ Refreshing font cache (macOS)..."
  atsutil databases -remove
  atsutil server -shutdown
  atsutil server -ping
else
  echo "⚠️  Font cache refresh not supported on this OS."
fi

# Cleanup
echo "→ Cleaning up..."
rm -f "${ZIP_FILE}"

echo "✅ ${FONT_NAME} Nerd Font installed successfully!"
