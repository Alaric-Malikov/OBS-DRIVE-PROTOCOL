@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: THUMB DRIVE LAUNCHER - start.bat
:: Place the contents of thumb-drive-launcher\ at your drive root.
:: ============================================================

:: Get the drive letter this script is running from
set DRIVE=%~d0
set LAUNCHER_DIR=%~dp0
set APP_DIR=%DRIVE%\app
set FM_DIR=%APP_DIR%\filemanager
set FM_PORT=8000
set FM_EXE=%FM_DIR%\filemanager.exe
set DRIVE_ROOT=%DRIVE%\

echo [Launcher] Starting from drive %DRIVE%

:: -----------------------------------------------------------
:: STEP 1: Decide whether to use the compiled exe or Python
:: -----------------------------------------------------------
if exist "%FM_EXE%" (
    echo [Launcher] Found compiled filemanager.exe — no Python required.
    set USE_EXE=1
) else (
    set USE_EXE=0
    where python >nul 2>&1
    if not errorlevel 1 (
        set PYTHON=python
    ) else (
        where py >nul 2>&1
        if not errorlevel 1 (
            set PYTHON=py
        ) else (
            if exist "%APP_DIR%\python\python.exe" (
                set PYTHON=%APP_DIR%\python\python.exe
            ) else (
                echo [Launcher] ERROR: Neither filemanager.exe nor Python was found.
                echo             Re-download the package from GitHub Releases, or install Python 3.
                pause
                exit /b 1
            )
        )
    )
    echo [Launcher] Using Python: %PYTHON%
)

:: -----------------------------------------------------------
:: STEP 2: (Python path only) Install Django if needed
:: -----------------------------------------------------------
if "%USE_EXE%"=="0" (
    %PYTHON% -c "import django" >nul 2>&1
    if errorlevel 1 (
        echo [Launcher] Django not found. Installing...
        %PYTHON% -m pip install -r "%FM_DIR%\requirements.txt" --quiet
        if errorlevel 1 (
            echo [Launcher] ERROR: Failed to install Django. Run: pip install django
            pause
            exit /b 1
        )
        echo [Launcher] Django installed.
    )
)

:: -----------------------------------------------------------
:: STEP 3: Start the web file manager
:: -----------------------------------------------------------
echo [Launcher] Starting file manager on port %FM_PORT%...

if "%USE_EXE%"=="1" (
    start "Drive File Manager" /min cmd /c "set DRIVE_ROOT=%DRIVE_ROOT% && "%FM_EXE%" 127.0.0.1:%FM_PORT%"
) else (
    start "Drive File Manager" /min cmd /c "set DRIVE_ROOT=%DRIVE_ROOT% && cd /d %FM_DIR% && %PYTHON% manage.py runserver 127.0.0.1:%FM_PORT% --noreload"
)

:: -----------------------------------------------------------
:: STEP 4: Background — silently wake the Replit project
:: -----------------------------------------------------------
echo [Launcher] Starting background Replit launcher...
start "" /min cmd /c "%LAUNCHER_DIR%background_launcher.bat"

:: -----------------------------------------------------------
:: STEP 5: Wait for the file manager to be ready
:: -----------------------------------------------------------
echo [Launcher] Waiting for file manager to start...
call "%LAUNCHER_DIR%wait_for_server.bat" 127.0.0.1 %FM_PORT% 30

if errorlevel 1 (
    echo [Launcher] WARNING: Server did not respond in time. Opening Chrome anyway...
)

:: -----------------------------------------------------------
:: STEP 6: Open Chrome to the file manager and external site
:: -----------------------------------------------------------
set TARGET_URL=http://127.0.0.1:%FM_PORT%/
echo [Launcher] Opening file manager in Chrome...
call "%LAUNCHER_DIR%open_chrome.bat" "%TARGET_URL%"

set EXTERNAL_URL=https://dbd1f9ab-ac3b-40fd-82a8-6c585b547c20-00-116alfcdzc3ss.riker.replit.dev/UnitDB
echo [Launcher] Opening external site in Chrome...
call "%LAUNCHER_DIR%open_chrome.bat" "%EXTERNAL_URL%"

echo [Launcher] Ready.
endlocal
