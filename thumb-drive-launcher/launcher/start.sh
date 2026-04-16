#!/usr/bin/env bash
# ============================================================
# start.sh — Linux / ChromeOS launcher
# Place the contents of thumb-drive-launcher/ at your drive root.
# Run with:  bash /path/to/drive/launcher/start.sh
# ============================================================
set -euo pipefail

LAUNCHER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRIVE_ROOT="$(cd "$LAUNCHER_DIR/.." && pwd)"
APP_DIR="$DRIVE_ROOT/app"
FM_DIR="$APP_DIR/filemanager"
FM_PORT=8000
PIDFILE="/tmp/drive_fm.pid"
WAKE_PID_FILE="/tmp/drive_wake.pid"

export DRIVE_ROOT
echo "[Launcher] Starting from: $DRIVE_ROOT"

# -----------------------------------------------------------
# STEP 1: Find Python 3
# -----------------------------------------------------------
PYTHON=""
for candidate in python3 python; do
    if command -v "$candidate" &>/dev/null; then
        PYTHON="$candidate"
        break
    fi
done

if [ -z "$PYTHON" ]; then
    echo "[Launcher] ERROR: Python 3 not found."
    echo "           Install it with:  sudo apt install python3 python3-pip"
    read -rp "Press Enter to exit..." _
    exit 1
fi
echo "[Launcher] Using: $PYTHON"

# -----------------------------------------------------------
# STEP 2: Install Django if needed
# -----------------------------------------------------------
if ! "$PYTHON" -c "import django" &>/dev/null; then
    echo "[Launcher] Django not found. Installing..."
    "$PYTHON" -m pip install -r "$FM_DIR/requirements.txt" --quiet
    echo "[Launcher] Django installed."
fi

# -----------------------------------------------------------
# STEP 3: Start the web file manager
# -----------------------------------------------------------
echo "[Launcher] Starting file manager on port $FM_PORT..."
(cd "$FM_DIR" && "$PYTHON" manage.py runserver "127.0.0.1:$FM_PORT" --noreload) &
echo $! > "$PIDFILE"

# -----------------------------------------------------------
# STEP 4: Background — silently wake the Replit project
# -----------------------------------------------------------
echo "[Launcher] Starting background Replit wake-up..."
bash "$LAUNCHER_DIR/background_launcher.sh" &
echo $! > "$WAKE_PID_FILE"

# -----------------------------------------------------------
# STEP 5: Wait for the file manager to be ready
# -----------------------------------------------------------
echo "[Launcher] Waiting for file manager to start..."
bash "$LAUNCHER_DIR/wait_for_server.sh" 127.0.0.1 "$FM_PORT" 30 || \
    echo "[Launcher] WARNING: Server slow to respond — opening browser anyway..."

# -----------------------------------------------------------
# STEP 6: Open browser
# -----------------------------------------------------------
TARGET_URL="http://127.0.0.1:$FM_PORT/"
echo "[Launcher] Opening file manager..."
bash "$LAUNCHER_DIR/open_browser.sh" "$TARGET_URL"

EXTERNAL_URL="https://dbd1f9ab-ac3b-40fd-82a8-6c585b547c20-00-116alfcdzc3ss.riker.replit.dev/UnitDB"
echo "[Launcher] Opening external site..."
bash "$LAUNCHER_DIR/open_browser.sh" "$EXTERNAL_URL"

echo "[Launcher] Ready. Run stop.sh before removing the drive."
