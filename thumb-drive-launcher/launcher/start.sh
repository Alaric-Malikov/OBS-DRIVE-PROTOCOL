#!/usr/bin/env bash
# ============================================================
# start.sh — Linux / ChromeOS launcher
# Place the contents of thumb-drive-launcher/ at your drive root.
# Run once with:  bash /media/YOUR_DRIVE/launcher/start.sh
# ============================================================
set -euo pipefail

LAUNCHER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRIVE_ROOT="$(cd "$LAUNCHER_DIR/.." && pwd)"
APP_DIR="$DRIVE_ROOT/app"
FM_DIR="$APP_DIR/filemanager"
FM_PORT=8000
FM_EXE="$FM_DIR/linux/filemanager"     # Linux compiled binary
PIDFILE="/tmp/drive_fm.pid"
WAKE_PID_FILE="/tmp/drive_wake.pid"

echo "[Launcher] Starting from: $DRIVE_ROOT"

# -----------------------------------------------------------
# STEP 1: Decide whether to use the compiled binary or Python
# -----------------------------------------------------------
export DRIVE_ROOT

if [ -f "$FM_EXE" ] && [ -x "$FM_EXE" ]; then
    echo "[Launcher] Found compiled filemanager binary — no Python required."
    USE_EXE=1
else
    USE_EXE=0
    PYTHON=""
    for candidate in python3 python; do
        if command -v "$candidate" &>/dev/null; then
            PYTHON="$candidate"
            break
        fi
    done

    if [ -z "$PYTHON" ]; then
        echo "[Launcher] ERROR: Neither a compiled binary nor Python 3 was found."
        echo "           Install Python 3 with:  sudo apt install python3 python3-pip"
        read -rp "Press Enter to exit..." _
        exit 1
    fi
    echo "[Launcher] Using Python: $PYTHON"
fi

# -----------------------------------------------------------
# STEP 2: (Python path only) Install Django if needed
# -----------------------------------------------------------
if [ "$USE_EXE" -eq 0 ]; then
    if ! "$PYTHON" -c "import django" &>/dev/null; then
        echo "[Launcher] Django not found. Installing..."
        "$PYTHON" -m pip install -r "$FM_DIR/requirements.txt" --quiet
        echo "[Launcher] Django installed."
    fi
fi

# -----------------------------------------------------------
# STEP 3: Start the web file manager
# -----------------------------------------------------------
echo "[Launcher] Starting file manager on port $FM_PORT..."

if [ "$USE_EXE" -eq 1 ]; then
    "$FM_EXE" "127.0.0.1:$FM_PORT" &
else
    (cd "$FM_DIR" && "$PYTHON" manage.py runserver "127.0.0.1:$FM_PORT" --noreload) &
fi
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
