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

echo [Launcher] Starting from drive %DRIVE%

:: -----------------------------------------------------------
:: STEP 1: Locate Python
:: -----------------------------------------------------------
where python >nul 2>&1
if not errorlevel 1 (
    set PYTHON=python
) else (
    where py >nul 2>&1
    if not errorlevel 1 (
        set PYTHON=py
    ) else (
        :: Try portable Python bundled on the drive
        if exist "%APP_DIR%\python\python.exe" (
            set PYTHON=%APP_DIR%\python\python.exe
        ) else (
            echo [Launcher] ERROR: Python not found.
            echo             Install Python 3 or place a portable Python in:
            echo             %APP_DIR%\python\python.exe
            pause
            exit /b 1
        )
    )
)
echo [Launcher] Using Python: %PYTHON%

:: -----------------------------------------------------------
:: STEP 2: (First run) Install Django if needed
:: -----------------------------------------------------------
%PYTHON% -c "import django" >nul 2>&1
if errorlevel 1 (
    echo [Launcher] Django not found. Installing from requirements.txt...
    %PYTHON% -m pip install -r "%FM_DIR%\requirements.txt" --quiet
    if errorlevel 1 (
        echo [Launcher] ERROR: Failed to install Django.
        echo             Run manually: pip install django
        pause
        exit /b 1
    )
    echo [Launcher] Django installed successfully.
)

:: -----------------------------------------------------------
:: STEP 3: Start the web file manager (Django)
::         DRIVE_ROOT tells it which folder to browse.
::         Set it to the drive root so users can browse everything.
:: -----------------------------------------------------------
set DRIVE_ROOT=%DRIVE%\
echo [Launcher] Starting file manager on port %FM_PORT%...
start "Drive File Manager" /min cmd /c "set DRIVE_ROOT=%DRIVE_ROOT% && cd /d %FM_DIR% && %PYTHON% manage.py runserver 127.0.0.1:%FM_PORT% --noreload"

:: -----------------------------------------------------------
:: STEP 4: (Optional) Run your own custom program
:: -----------------------------------------------------------
:: Uncomment and edit the line below to also launch your own program.
::
:: start "" "%APP_DIR%\myapp\myapp.exe"
:: -- OR --
:: start "My App" cmd /c "%PYTHON% %APP_DIR%\myapp\main.py"

:: -----------------------------------------------------------
:: STEP 5: Wait for the file manager to be ready
:: -----------------------------------------------------------
echo [Launcher] Waiting for file manager to start...
call "%LAUNCHER_DIR%wait_for_server.bat" 127.0.0.1 %FM_PORT% 30

if errorlevel 1 (
    echo [Launcher] WARNING: Server did not respond in time. Trying Chrome anyway...
)

:: -----------------------------------------------------------
:: STEP 6: Open Chrome to the file manager
:: -----------------------------------------------------------
set TARGET_URL=http://127.0.0.1:%FM_PORT%/
echo [Launcher] Opening file manager in Chrome...
call "%LAUNCHER_DIR%open_chrome.bat" "%TARGET_URL%"

echo [Launcher] Ready. Close this window to keep the server running.
endlocal
