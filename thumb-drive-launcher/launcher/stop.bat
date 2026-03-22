@echo off
:: ============================================================
:: stop.bat - Stops all launcher processes.
:: Run this before safely removing the thumb drive.
:: ============================================================
echo [Launcher] Stopping file manager and any other launched programs...
taskkill /f /fi "WINDOWTITLE eq Drive File Manager*" >nul 2>&1
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im py.exe >nul 2>&1
echo [Launcher] All stopped. You may safely remove the drive.
pause
