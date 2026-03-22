@echo off
:: ============================================================
:: install_deps.bat
:: Run this ONCE after copying the drive contents to install
:: Django and any other Python dependencies.
:: ============================================================
setlocal

set DRIVE=%~d0
set APP_DIR=%DRIVE%\app
set FM_DIR=%APP_DIR%\filemanager

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
            echo ERROR: Python not found. Install Python 3 first.
            pause & exit /b 1
        )
    )
)

echo Installing Python dependencies...
%PYTHON% -m pip install -r "%FM_DIR%\requirements.txt"
if errorlevel 1 (
    echo ERROR: Installation failed.
    pause & exit /b 1
)

echo.
echo Done! You can now run launcher\start.bat
pause
endlocal
