#!/usr/bin/env bash
# ============================================================
# background_launcher.sh
# Wakes up the deployed Replit project by polling its URL
# before the user ever clicks "Open Site". Runs silently.
# Called automatically by start.sh — do not run manually.
# ============================================================

WAKE_URL="https://dbd1f9ab-ac3b-40fd-82a8-6c585b547c20-00-116alfcdzc3ss.riker.replit.dev/UnitDB"
MAX_TRIES=120

# Small delay so the main launcher finishes first
sleep 2

for ((i=1; i<=MAX_TRIES; i++)); do
    # Accept any HTTP response — even a redirect or 503 means the server is alive
    HTTP_CODE=$(curl --silent --max-time 8 --write-out "%{http_code}" \
                     --output /dev/null --location "$WAKE_URL" 2>/dev/null)
    if [ -n "$HTTP_CODE" ] && [ "$HTTP_CODE" != "000" ]; then
        exit 0
    fi
    sleep 1
done

exit 0
