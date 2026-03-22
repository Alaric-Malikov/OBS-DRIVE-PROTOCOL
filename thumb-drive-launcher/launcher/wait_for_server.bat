@echo off
:: ============================================================
:: wait_for_server.bat
:: Usage: wait_for_server.bat <host> <port> <timeout_seconds>
:: Polls a TCP port until it responds or timeout is reached.
:: Exits with 0 if server is ready, 1 if timed out.
:: ============================================================
setlocal enabledelayedexpansion

set HOST=%1
set PORT=%2
set TIMEOUT=%3

if "%HOST%"=="" set HOST=127.0.0.1
if "%PORT%"=="" set PORT=8000
if "%TIMEOUT%"=="" set TIMEOUT=30

set /a COUNT=0

:LOOP
    :: Use PowerShell to test TCP connection (available on all modern Windows)
    powershell -NoProfile -Command ^
        "try { $tcp = New-Object Net.Sockets.TcpClient('%HOST%', %PORT%); $tcp.Close(); exit 0 } catch { exit 1 }" >nul 2>&1

    if not errorlevel 1 (
        echo [Launcher] Server is ready on %HOST%:%PORT%.
        exit /b 0
    )

    set /a COUNT+=1
    if !COUNT! geq %TIMEOUT% (
        echo [Launcher] Timed out waiting for %HOST%:%PORT% after %TIMEOUT% seconds.
        exit /b 1
    )

    timeout /t 1 /nobreak >nul
    goto LOOP

endlocal
