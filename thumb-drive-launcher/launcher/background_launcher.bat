@echo off
:: ============================================================
:: background_launcher.bat
:: Silently opens an external Replit project in Chrome so it
:: loads and begins running. Called automatically by start.bat.
:: This window is hidden — do not run manually.
:: ============================================================
setlocal

set REPLIT_URL=https://replit.com/@Alaric-Malikov/OBSDBTERM

:: Small delay so the main launcher finishes first
timeout /t 3 /nobreak >nul

:: Find Chrome
set CHROME=

for %%P in (
    "%ProgramFiles%\Google\Chrome\Application\chrome.exe"
    "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
    "%LocalAppData%\Google\Chrome\Application\chrome.exe"
) do (
    if exist %%P (
        set CHROME=%%P
        goto :found
    )
)

:: Fallback to default browser
start "" "%REPLIT_URL%"
goto :end

:found
:: Open in a new Chrome tab (not app mode — keeps the Replit UI fully functional)
start "" %CHROME% --new-tab "%REPLIT_URL%"

:end
endlocal
