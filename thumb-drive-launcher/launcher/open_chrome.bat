@echo off
:: ============================================================
:: open_chrome.bat
:: Usage: open_chrome.bat <URL>
:: Opens Chrome in app mode (no address bar, clean kiosk-like UI).
:: Falls back to the default browser if Chrome is not found.
:: ============================================================
setlocal

set URL=%~1
if "%URL%"=="" set URL=http://127.0.0.1:8000/

:: Common Chrome install paths
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

:: Chrome not found — fall back to default browser
echo [Launcher] Chrome not found. Opening with default browser...
start "" "%URL%"
goto :end

:found
echo [Launcher] Opening Chrome: %URL%
start "" %CHROME% --app="%URL%" --window-size=1280,800

:end
endlocal
