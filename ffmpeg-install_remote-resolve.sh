#!/bin/bash
set -e

REPO_OWNER="probityrules"
REPO_NAME="DaVinci-Resolve-Video-Converter-for-Nautilus-File-Manager"
BRANCH="main"

TMPDIR="$(mktemp -d /tmp/ffmpegconvert-resolve.XXXXXX)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

echo "[Remote Installer] Creating temp workspace..."
cd "$TMPDIR"

echo "[Remote Installer] Downloading repo..."
curl -fsSL \
  -o repo.zip \
  "https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/refs/heads/${BRANCH}.zip"

echo "[Remote Installer] Extracting..."
unzip -q repo.zip
cd "${REPO_NAME}-${BRANCH}"

echo "[Remote Installer] Running installer..."
chmod +x install_uninstall-resolve.sh install.sh uninstall.sh
./install_uninstall-resolve.sh --install

echo "[Remote Installer] Done."
