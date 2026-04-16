@echo off
:: ============================================================
:: stop.bat - Full shutdown protocol.
:: Stops the Django file manager AND the background wake-up
:: polling process. Run before safely removing the drive.
:: ============================================================
echo [Launcher] Shutting down...

:: -- 1. Stop the Django file manager server --
echo [Launcher] Stopping file manager (Django)...
taskkill /f /fi "WINDOWTITLE eq Drive File Manager*" >nul 2>&1
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im py.exe >nul 2>&1

:: -- 2. Stop the background polling subprocess --
:: Kills any PowerShell processes that were polling the wake URL,
:: and the cmd window running background_launcher.bat.
echo [Launcher] Stopping background wake-up subprocess...
powershell -NoProfile -WindowStyle Hidden -Command ^
  "Get-WmiObject Win32_Process -Filter \"name='powershell.exe'\" ^
   | Where-Object { $_.CommandLine -like '*Invoke-WebRequest*riker.replit.dev*' } ^
   | ForEach-Object { $_.Terminate() }" >nul 2>&1

powershell -NoProfile -WindowStyle Hidden -Command ^
  "Get-WmiObject Win32_Process -Filter \"name='cmd.exe'\" ^
   | Where-Object { $_.CommandLine -like '*background_launcher*' } ^
   | ForEach-Object { $_.Terminate() }" >nul 2>&1

echo [Launcher] All processes stopped. You may safely remove the drive.
pause
