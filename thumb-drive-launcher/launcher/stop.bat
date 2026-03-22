@echo off
:: ============================================================
:: stop.bat - Stops the Django server and any running processes
:: Run this before safely removing the thumb drive.
:: ============================================================
echo [Launcher] Stopping Django server...
taskkill /f /fi "WINDOWTITLE eq Django Server*" >nul 2>&1
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im py.exe >nul 2>&1
echo [Launcher] Done. You may safely remove the drive.
pause
