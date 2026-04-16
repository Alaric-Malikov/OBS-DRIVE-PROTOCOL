@echo off
:: ============================================================
:: background_launcher.bat
:: Wakes up the deployed Replit project by polling its URL
:: before the user ever clicks "Open Site". Runs hidden.
:: Called automatically by start.bat — do not run manually.
:: ============================================================
setlocal

set WAKE_URL=https://dbd1f9ab-ac3b-40fd-82a8-6c585b547c20-00-116alfcdzc3ss.riker.replit.dev/UnitDB

:: Small delay so the main launcher finishes first
timeout /t 2 /nobreak >nul

:: Poll until ANY HTTP response is received (up to 120 seconds)
:: A response — even a redirect or 503 — means the server is waking up.
set /a TRIES=0
:POLL
    set /a TRIES+=1
    if %TRIES% gtr 120 goto :GIVE_UP

    powershell -NoProfile -WindowStyle Hidden -Command ^
        "try { $r = Invoke-WebRequest -Uri '%WAKE_URL%' -UseBasicParsing -TimeoutSec 8 -MaximumRedirection 5; exit 0 } catch [System.Net.WebException] { if ($_.Exception.Response) { exit 0 } exit 1 } catch { exit 1 }" >nul 2>&1

    if not errorlevel 1 goto :ALIVE

    timeout /t 1 /nobreak >nul
    goto :POLL

:ALIVE
    goto :EOF

:GIVE_UP
    goto :EOF

endlocal
