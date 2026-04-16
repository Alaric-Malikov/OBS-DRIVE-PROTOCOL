#!/usr/bin/env bash
# ============================================================
# stop.sh — Linux / ChromeOS shutdown
# Run before safely removing the drive.
# ============================================================

PIDFILE="/tmp/drive_fm.pid"
WAKE_PID_FILE="/tmp/drive_wake.pid"

echo "[Launcher] Shutting down..."

# -- Stop file manager --
if [ -f "$PIDFILE" ]; then
    FM_PID=$(cat "$PIDFILE")
    if kill -0 "$FM_PID" 2>/dev/null; then
        echo "[Launcher] Stopping file manager (PID $FM_PID)..."
        kill "$FM_PID" 2>/dev/null
    fi
    rm -f "$PIDFILE"
fi

# Also kill by process name in case PID file is stale
pkill -f "manage.py runserver" 2>/dev/null || true
pkill -f "filemanager 127.0.0.1" 2>/dev/null || true

# -- Stop background wake-up poller --
if [ -f "$WAKE_PID_FILE" ]; then
    WAKE_PID=$(cat "$WAKE_PID_FILE")
    if kill -0 "$WAKE_PID" 2>/dev/null; then
        echo "[Launcher] Stopping background wake-up process (PID $WAKE_PID)..."
        kill "$WAKE_PID" 2>/dev/null
        # Kill any child curl processes it spawned
        pkill -P "$WAKE_PID" 2>/dev/null || true
    fi
    rm -f "$WAKE_PID_FILE"
fi

pkill -f "background_launcher.sh" 2>/dev/null || true

echo "[Launcher] All processes stopped. You may safely remove the drive."
