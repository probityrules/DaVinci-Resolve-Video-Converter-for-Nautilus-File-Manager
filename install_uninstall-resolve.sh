#!/bin/bash
set -e

########################################
# CONFIG
########################################

CONFIG_DIR="$HOME/.config/ffmpegconvert"
CONFIG_FILE="$CONFIG_DIR/install-resolve.conf"
MANIFEST_FILE="$CONFIG_DIR/manifest-resolve.txt"

mkdir -p "$CONFIG_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_SOURCE="$SCRIPT_DIR/release/ffmpegconvert-resolve.sh"
EXT_SOURCE="$SCRIPT_DIR/release/nautilus-python/ffmpegconvert_resolve.py"

DEFAULT_SCRIPT_DIR="$HOME/.local/bin"
DEFAULT_SCRIPT_PATH="$HOME/.local/bin/ffmpegconvert-resolve.sh"

USER_EXT_DIR="$HOME/.local/share/nautilus-python/extensions"
SYSTEM_EXT_DIR="/usr/share/nautilus-python/extensions"
USER_SCRIPTS_DIR="$HOME/.local/share/nautilus/scripts"
EXT_NAME="ffmpegconvert_resolve.py"
LEGACY_NAUTILUS_SCRIPT_NAME="Convert for Resolve"

########################################
# SAFETY CHECK
########################################

if [ ! -f "$SCRIPT_SOURCE" ]; then
    echo "ERROR: release/ffmpegconvert-resolve.sh not found next to installer"
    exit 1
fi
if [ ! -f "$EXT_SOURCE" ]; then
    echo "ERROR: release/nautilus-python/ffmpegconvert_resolve.py not found"
    exit 1
fi

########################################
# MODE
########################################

MODE="$1"

if [ "$MODE" == "--install" ]; then
    UNINSTALL=0
elif [ "$MODE" == "--uninstall" ]; then
    UNINSTALL=1
else
    [ -f "$CONFIG_FILE" ] && UNINSTALL=1 || UNINSTALL=0
fi

########################################
# HELPERS
########################################

ask() { read -rp "$1 " r; echo "$r"; }
confirm() { read -rp "$1 [y/N]: " r; [[ "$r" =~ ^[Yy]$ ]]; }

refresh_nautilus() {
    if command -v nautilus >/dev/null 2>&1; then
        echo "Restarting Nautilus (nautilus -q)..."
        nautilus -q >/dev/null 2>&1 || true
    else
        echo "Note: nautilus not found in PATH; reopen Nautilus manually to load changes."
    fi
}

print_nautilus_python_hints() {
    echo "  Debian/Ubuntu:  sudo apt install python3-nautilus"
    echo "  Fedora:         sudo dnf install nautilus-python"
    echo "  Arch:           sudo pacman -S python-nautilus"
}

########################################
# DEPENDENCIES
########################################

missing=()
command -v ffmpeg >/dev/null 2>&1 || missing+=("ffmpeg")
command -v ffprobe >/dev/null 2>&1 || missing+=("ffprobe")
command -v zenity >/dev/null 2>&1 || missing+=("zenity")

if [ ${#missing[@]} -gt 0 ]; then
    echo "WARNING: missing required tools: ${missing[*]}"
    echo "Install them before converting videos."
    echo
fi

echo "This installer requires python3-nautilus (Nautilus Python extensions)."
echo "If the context menu does not appear after install, install the package for your distro:"
print_nautilus_python_hints
echo

########################################
# LOAD CONFIG (uninstall)
########################################

USE_SUDO=0
SCRIPT_PATH=""
TARGET_EXT_DIR=""
NAUTILUS_SCRIPT_PATH=""

if [ "$UNINSTALL" -eq 1 ] && [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
fi

########################################
# UNINSTALL
########################################

if [ "$UNINSTALL" -eq 1 ]; then

    echo "========================================"
    echo "Resolve Convert — Uninstall (Nautilus)"
    echo "========================================"
    echo

    echo "Converter script:"
    echo "  ${SCRIPT_PATH:-"(unknown)"}"
    echo
    echo "Extension directory:"
    echo "  ${TARGET_EXT_DIR:-"(none)"}"
    echo

    confirm "Continue uninstall?" || exit 0

    echo
    echo "Removing installed files..."

    FAILED=0

    if [ -f "$MANIFEST_FILE" ]; then
        while IFS= read -r f; do
            [ -z "$f" ] && continue
            echo "Deleting: $f"
            if [[ "$f" == "$HOME"/* ]]; then
                rm -f -- "$f" || true
            else
                if [ "${USE_SUDO:-0}" -eq 1 ]; then
                    sudo rm -f -- "$f" || true
                else
                    rm -f -- "$f" || true
                fi
            fi
            if [ -e "$f" ]; then
                echo "FAILED: $f"
                FAILED=1
            fi
        done < "$MANIFEST_FILE"
    fi

    for f in \
        "${SCRIPT_PATH}" \
        "${TARGET_EXT_DIR}/${EXT_NAME}" \
        "${USER_EXT_DIR}/${EXT_NAME}" \
        "${SYSTEM_EXT_DIR}/${EXT_NAME}" \
        "${NAUTILUS_SCRIPT_PATH}" \
        "${USER_SCRIPTS_DIR}/${LEGACY_NAUTILUS_SCRIPT_NAME}"
    do
        [ -z "$f" ] && continue
        [ -e "$f" ] || continue
        echo "Deleting (fallback): $f"
        if [[ "$f" == "$HOME"/* ]]; then
            rm -f -- "$f" || true
        else
            sudo rm -f -- "$f" 2>/dev/null || rm -f -- "$f" || true
        fi
        if [ -e "$f" ]; then
            echo "FAILED: $f"
            FAILED=1
        fi
    done

    refresh_nautilus

    echo
    if [ "$FAILED" -eq 0 ]; then
        echo "Uninstall complete."
    else
        echo "Uninstall finished with some failures (check permissions)."
    fi

    rm -f "$CONFIG_FILE" "$MANIFEST_FILE"
    exit 0
fi

########################################
# INSTALL
########################################

echo "========================================"
echo "Resolve Convert — Install (Nautilus)"
echo "========================================"
echo

USE_SUDO=0

echo "Extension install scope:"
echo "1) User  (~/.local/share/nautilus-python/extensions)"
echo "2) System (/usr/share/nautilus-python/extensions)"
scope=$(ask "Select [1-2] (default 1):")
if [ "$scope" == "2" ]; then
    TARGET_EXT_DIR="$SYSTEM_EXT_DIR"
    USE_SUDO=1
else
    TARGET_EXT_DIR="$USER_EXT_DIR"
    USE_SUDO=0
fi

########################################
# SCRIPT INSTALL
########################################

echo
echo "Converter script location (default: $DEFAULT_SCRIPT_DIR)"
custom=$(ask "Custom directory (Enter = default):")

if [ -z "$custom" ]; then
    SCRIPT_DEST="$DEFAULT_SCRIPT_PATH"
else
    SCRIPT_DEST="$custom/ffmpegconvert-resolve.sh"
    mkdir -p "$custom"
fi

mkdir -p "$(dirname "$SCRIPT_DEST")"
cp "$SCRIPT_SOURCE" "$SCRIPT_DEST"
chmod +x "$SCRIPT_DEST"
echo "Installed converter → $SCRIPT_DEST"

> "$MANIFEST_FILE"
echo "$SCRIPT_DEST" >> "$MANIFEST_FILE"

########################################
# EXTENSION
########################################

echo "Installing Nautilus Python extension → $TARGET_EXT_DIR"
if [ "$USE_SUDO" -eq 1 ]; then
    sudo mkdir -p "$TARGET_EXT_DIR"
else
    mkdir -p "$TARGET_EXT_DIR"
fi

tmp="$(mktemp)"
escaped_path="${SCRIPT_DEST//\\/\\\\}"
escaped_path="${escaped_path//\"/\\\"}"
sed "s|^SCRIPT_PATH = .*|SCRIPT_PATH = \"${escaped_path}\"|" "$EXT_SOURCE" > "$tmp"

dest="$TARGET_EXT_DIR/$EXT_NAME"
if [ "$USE_SUDO" -eq 1 ]; then
    sudo cp "$tmp" "$dest"
    sudo chmod 644 "$dest"
else
    cp "$tmp" "$dest"
    chmod 644 "$dest"
fi
rm -f "$tmp"
echo "$dest" >> "$MANIFEST_FILE"
echo "Installed extension → $dest"

# Remove legacy Scripts fallback from older installs
legacy_script="$USER_SCRIPTS_DIR/$LEGACY_NAUTILUS_SCRIPT_NAME"
if [ -e "$legacy_script" ]; then
    echo "Removing legacy Nautilus Scripts entry → $legacy_script"
    rm -f -- "$legacy_script" || true
fi

########################################
# REFRESH + SAVE CONFIG
########################################

refresh_nautilus

cat > "$CONFIG_FILE" <<EOF
SCRIPT_PATH="$SCRIPT_DEST"
TARGET_EXT_DIR="$TARGET_EXT_DIR"
USE_SUDO="$USE_SUDO"
INTEGRATION_MODE="extension"
EOF

echo
echo "Installation complete."
echo "Open Nautilus, right-click a video → Convert for Resolve"
echo "  (or right-click a .mov → Convert MOV to MP4)."
echo
echo "To uninstall later: ./uninstall.sh"
echo "  or: ./install_uninstall-resolve.sh --uninstall"
