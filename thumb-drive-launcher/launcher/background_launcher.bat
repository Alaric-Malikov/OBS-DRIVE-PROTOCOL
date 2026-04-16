@echo off
:: ============================================================
:: background_launcher.bat
:: Silently triggers the external Replit project with no
:: visible window, tab, or taskbar entry.
:: Called automatically by start.bat — do not run manually.
:: ============================================================
setlocal

set REPLIT_URL=https://replit.com/@Alaric-Malikov/OBSDBTERM

:: Small delay so the main launcher finishes first
timeout /t 3 /nobreak >nul

:: Use the VBScript wrapper to open Chrome fully hidden (window style 0)
:: wscript runs VBS silently — no console window appears
wscript.exe //NoLogo "%~dp0hidden_chrome.vbs" "%REPLIT_URL%"

endlocal
