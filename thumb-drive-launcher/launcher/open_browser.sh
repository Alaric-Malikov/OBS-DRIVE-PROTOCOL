#!/usr/bin/env bash
# ============================================================
# open_browser.sh
# Usage: open_browser.sh <URL>
# Opens Chrome/Chromium. Works on Linux and ChromeOS.
# ============================================================

URL="${1:-http://127.0.0.1:8000/}"

# Try Chrome / Chromium executables in order of preference
for browser in \
    google-chrome \
    google-chrome-stable \
    chromium-browser \
    chromium \
    google-chrome-unstable \
    google-chrome-beta; do
    if command -v "$browser" &>/dev/null; then
        echo "[Launcher] Opening $URL with $browser"
        "$browser" --app="$URL" --window-size=1280,800 &
        exit 0
    fi
done

# ChromeOS Linux (Crostini): use garcon to open in the host ChromeOS browser
if command -v garcon-url-handler &>/dev/null; then
    echo "[Launcher] Opening $URL via ChromeOS browser"
    garcon-url-handler "$URL"
    exit 0
fi

# Generic Linux fallback
if command -v xdg-open &>/dev/null; then
    echo "[Launcher] Opening $URL with xdg-open"
    xdg-open "$URL"
    exit 0
fi

echo "[Launcher] No browser found. Open manually: $URL"
exit 1
