#!/usr/bin/env bash
# ============================================================
# background_launcher.sh
# Wakes up the deployed Replit project by polling its URL
# before the user ever clicks "Open Site". Runs silently.
# Called automatically by start.sh — do not run manually.
# ============================================================

WAKE_URL="https://dbd1f9ab-ac3b-40fd-82a8-6c585b547c20-00-116alfcdzc3ss.riker.replit.dev/UnitDB"
MAX_TRIES=60

# Small delay so the main launcher finishes first
sleep 2

for ((i=1; i<=MAX_TRIES; i++)); do
    if curl --silent --max-time 5 --output /dev/null "$WAKE_URL"; then
        # Server is up — nothing more needed.
        # The "Open Site" button will now load instantly.
        exit 0
    fi
    sleep 1
done

# Could not reach the server in time — silently exit.
exit 0
