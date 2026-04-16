@echo off
:: ============================================================
:: background_launcher.bat
:: Wakes up the deployed Replit project by polling its URL
:: before the user ever clicks "Open Site". Runs hidden.
:: Called automatically by start.bat — do not run manually.
:: ============================================================
setlocal

:: This must match the TARGET_URL in start.bat exactly
set WAKE_URL=https://dbd1f9ab-ac3b-40fd-82a8-6c585b547c20-00-116alfcdzc3ss.riker.replit.dev/UnitDB

:: Small delay so the main launcher finishes first
timeout /t 2 /nobreak >nul

:: Poll until the server responds (up to 60 seconds, 1s between tries)
set /a TRIES=0
:POLL
    set /a TRIES+=1
    if %TRIES% gtr 60 goto :GIVE_UP

    powershell -NoProfile -WindowStyle Hidden -Command ^
        "try { $r = Invoke-WebRequest -Uri '%WAKE_URL%' -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1

    if not errorlevel 1 goto :ALIVE

    timeout /t 1 /nobreak >nul
    goto :POLL

:ALIVE
    :: Server is up — nothing more needed.
    :: The "Open Site" button in the file manager will now open instantly.
    goto :EOF

:GIVE_UP
    :: Could not reach the server in time — silently exit.
    goto :EOF

endlocal
