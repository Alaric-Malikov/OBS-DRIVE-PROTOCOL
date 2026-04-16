@echo off
:: ============================================================
:: stop.bat - Full shutdown protocol.
:: Stops the Django file manager AND the hidden background
:: Chrome subprocess. Run before safely removing the drive.
:: ============================================================
echo [Launcher] Shutting down...

:: -- 1. Stop the Django file manager server --
echo [Launcher] Stopping file manager (Django)...
taskkill /f /fi "WINDOWTITLE eq Drive File Manager*" >nul 2>&1
taskkill /f /im python.exe >nul 2>&1
taskkill /f /im py.exe >nul 2>&1

:: -- 2. Stop the hidden headless Chrome subprocess --
:: We only kill chrome.exe processes whose command line contains
:: '--headless', so the user's regular Chrome windows are untouched.
echo [Launcher] Stopping hidden background subprocess (headless Chrome)...
powershell -NoProfile -WindowStyle Hidden -Command ^
  "Get-WmiObject Win32_Process -Filter \"name='chrome.exe'\" ^
   | Where-Object { $_.CommandLine -like '*--headless*' } ^
   | ForEach-Object { $_.Terminate() }" >nul 2>&1

:: -- 3. Kill the wscript/background_launcher host process (if still alive) --
powershell -NoProfile -WindowStyle Hidden -Command ^
  "Get-WmiObject Win32_Process -Filter \"name='wscript.exe'\" ^
   | Where-Object { $_.CommandLine -like '*hidden_chrome*' } ^
   | ForEach-Object { $_.Terminate() }" >nul 2>&1

echo [Launcher] All processes stopped. You may safely remove the drive.
pause
