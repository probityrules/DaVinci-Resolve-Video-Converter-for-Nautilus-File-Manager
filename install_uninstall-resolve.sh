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
NAUTILUS_SCRIPT_SOURCE="$SCRIPT_DIR/release/nautilus-scripts/Convert for Resolve"

DEFAULT_SCRIPT_DIR="$HOME/.local/bin"
DEFAULT_SCRIPT_PATH="$HOME/.local/bin/ffmpegconvert-resolve.sh"

USER_EXT_DIR="$HOME/.local/share/nautilus-python/extensions"
SYSTEM_EXT_DIR="/usr/share/nautilus-python/extensions"
USER_SCRIPTS_DIR="$HOME/.local/share/nautilus/scripts"
EXT_NAME="ffmpegconvert_resolve.py"
NAUTILUS_SCRIPT_NAME="Convert for Resolve"

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
if [ ! -f "$NAUTILUS_SCRIPT_SOURCE" ]; then
    echo "ERROR: release/nautilus-scripts/Convert for Resolve not found"
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

detect_nautilus_python() {
    if python3 - <<'PY' >/dev/null 2>&1
import gi
gi.require_version("Nautilus", "4.0")
from gi.repository import Nautilus  # noqa: F401
PY
    then
        return 0
    fi
    if python3 - <<'PY' >/dev/null 2>&1
import gi
gi.require_version("Nautilus", "3.0")
from gi.repository import Nautilus  # noqa: F401
PY
    then
        return 0
    fi
    return 1
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

########################################
# LOAD CONFIG (uninstall)
########################################

USE_SUDO=0
SCRIPT_PATH=""
TARGET_EXT_DIR=""
INTEGRATION_MODE=""
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
    echo "Nautilus script:"
    echo "  ${NAUTILUS_SCRIPT_PATH:-"(none)"}"
    echo
    echo "Integration mode:"
    echo "  ${INTEGRATION_MODE:-"(unknown)"}"
    echo

    confirm "Continue uninstall?" || exit 0

    echo
    echo "Removing installed files..."

    REMOVED=0
    FAILED=0

    if [ -f "$MANIFEST_FILE" ]; then
        while IFS= read -r f; do
            [ -z "$f" ] && continue
            echo "Deleting: $f"
            # Prefer sudo only for paths outside $HOME
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
            else
                REMOVED=1
            fi
        done < "$MANIFEST_FILE"
    fi

    # Fallback removals
    for f in \
        "${SCRIPT_PATH}" \
        "${TARGET_EXT_DIR}/${EXT_NAME}" \
        "${USER_EXT_DIR}/${EXT_NAME}" \
        "${SYSTEM_EXT_DIR}/${EXT_NAME}" \
        "${NAUTILUS_SCRIPT_PATH}" \
        "${USER_SCRIPTS_DIR}/${NAUTILUS_SCRIPT_NAME}"
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
        else
            REMOVED=1
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

HAS_NAUTILUS_PYTHON=0
if detect_nautilus_python; then
    HAS_NAUTILUS_PYTHON=1
    echo "Detected python3-nautilus / nautilus-python."
else
    echo "python3-nautilus not detected (top-level context menu unavailable)."
    print_nautilus_python_hints
fi
echo

INTEGRATION_MODE="scripts"
USE_SUDO=0
TARGET_EXT_DIR=""

if [ "$HAS_NAUTILUS_PYTHON" -eq 1 ]; then
    echo "Integration:"
    echo "1) Python extension (top-level \"Convert for Resolve\") [recommended]"
    echo "2) Nautilus Scripts fallback (under Scripts submenu)"
    choice=$(ask "Select [1-2] (default 1):")
    if [ "$choice" == "2" ]; then
        INTEGRATION_MODE="scripts"
    else
        INTEGRATION_MODE="extension"
    fi
else
    echo "Installing Nautilus Scripts fallback automatically."
    INTEGRATION_MODE="scripts"
fi

if [ "$INTEGRATION_MODE" == "extension" ]; then
    echo
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
# EXTENSION OR SCRIPTS
########################################

NAUTILUS_SCRIPT_PATH=""

if [ "$INTEGRATION_MODE" == "extension" ]; then
    echo "Installing Nautilus Python extension → $TARGET_EXT_DIR"
    if [ "$USE_SUDO" -eq 1 ]; then
        sudo mkdir -p "$TARGET_EXT_DIR"
    else
        mkdir -p "$TARGET_EXT_DIR"
    fi

    tmp="$(mktemp)"
    # Escape backslashes and quotes for a Python string literal
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
else
    echo "Installing Nautilus Scripts fallback → $USER_SCRIPTS_DIR"
    mkdir -p "$USER_SCRIPTS_DIR"
    tmp="$(mktemp)"
    sed "s|^SCRIPT_PATH=.*|SCRIPT_PATH=\"${SCRIPT_DEST}\"|" "$NAUTILUS_SCRIPT_SOURCE" > "$tmp"
    dest="$USER_SCRIPTS_DIR/$NAUTILUS_SCRIPT_NAME"
    cp "$tmp" "$dest"
    chmod +x "$dest"
    rm -f "$tmp"
    NAUTILUS_SCRIPT_PATH="$dest"
    echo "$dest" >> "$MANIFEST_FILE"
    echo "Installed script → $dest"
fi

########################################
# REFRESH + SAVE CONFIG
########################################

refresh_nautilus

cat > "$CONFIG_FILE" <<EOF
SCRIPT_PATH="$SCRIPT_DEST"
TARGET_EXT_DIR="$TARGET_EXT_DIR"
USE_SUDO="$USE_SUDO"
INTEGRATION_MODE="$INTEGRATION_MODE"
NAUTILUS_SCRIPT_PATH="$NAUTILUS_SCRIPT_PATH"
EOF

echo
echo "Installation complete."
if [ "$INTEGRATION_MODE" == "extension" ]; then
    echo "Open Nautilus, right-click a video → Convert for Resolve."
else
    echo "Open Nautilus, right-click a video → Scripts → Convert for Resolve."
fi
echo
echo "To uninstall later: ./uninstall.sh"
echo "  or: ./install_uninstall-resolve.sh --uninstall"
