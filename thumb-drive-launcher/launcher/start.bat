@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: THUMB DRIVE LAUNCHER - start.bat
:: Place this file at: <drive>:\launcher\start.bat
:: ============================================================

:: Get the drive letter this script is running from
set DRIVE=%~d0
set LAUNCHER_DIR=%~dp0
set APP_DIR=%DRIVE%\app

echo [Launcher] Starting...

:: -----------------------------------------------------------
:: STEP 1: Start your Django app
:: -----------------------------------------------------------
:: Adjust the path below to point to your Django manage.py
:: and set the port your Django app runs on.

set DJANGO_PORT=8000
set DJANGO_DIR=%APP_DIR%\django

:: Check if Python is available
where python >nul 2>&1
if errorlevel 1 (
    :: Try py launcher
    where py >nul 2>&1
    if errorlevel 1 (
        echo [Launcher] ERROR: Python not found on this system.
        echo             Please install Python and try again.
        pause
        exit /b 1
    )
    set PYTHON=py
) else (
    set PYTHON=python
)

:: Start Django server in a new background window
echo [Launcher] Starting Django server on port %DJANGO_PORT%...
start "Django Server" /min cmd /c "cd /d %DJANGO_DIR% && %PYTHON% manage.py runserver 127.0.0.1:%DJANGO_PORT%"

:: -----------------------------------------------------------
:: STEP 2: (Optional) Run your custom file system program
:: -----------------------------------------------------------
:: Uncomment and edit the line below to run your custom program.
:: It can be an .exe, a Python script, or anything else.
::
:: start "" "%APP_DIR%\my_program\my_program.exe"
:: -- OR --
:: start "" %PYTHON% "%APP_DIR%\my_program\main.py"

:: -----------------------------------------------------------
:: STEP 3: Wait for Django to be ready, then open Chrome
:: -----------------------------------------------------------
echo [Launcher] Waiting for Django server to start...
call "%LAUNCHER_DIR%wait_for_server.bat" 127.0.0.1 %DJANGO_PORT% 30

if errorlevel 1 (
    echo [Launcher] WARNING: Django server did not respond in time.
    echo             Attempting to open Chrome anyway...
)

:: -----------------------------------------------------------
:: STEP 4: Open Chrome to your URL
:: -----------------------------------------------------------
:: Replace the URL below with your actual target URL.
set TARGET_URL=https://YOUR-URL-HERE.com

echo [Launcher] Opening Chrome to %TARGET_URL%...
call "%LAUNCHER_DIR%open_chrome.bat" "%TARGET_URL%"

echo [Launcher] Done.
endlocal
