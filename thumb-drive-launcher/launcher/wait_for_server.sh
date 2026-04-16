#!/usr/bin/env bash
# ============================================================
# wait_for_server.sh
# Usage: wait_for_server.sh <host> <port> <timeout_seconds>
# Polls until the port responds or timeout is reached.
# Exits 0 if ready, 1 if timed out.
# ============================================================

HOST="${1:-127.0.0.1}"
PORT="${2:-8000}"
TIMEOUT="${3:-30}"

for ((i=1; i<=TIMEOUT; i++)); do
    # Use /dev/tcp (bash built-in) — works without curl/nc
    if (echo > /dev/tcp/"$HOST"/"$PORT") &>/dev/null; then
        echo "[Launcher] Server is ready on $HOST:$PORT"
        exit 0
    fi
    sleep 1
done

echo "[Launcher] Timed out waiting for $HOST:$PORT after ${TIMEOUT}s"
exit 1
