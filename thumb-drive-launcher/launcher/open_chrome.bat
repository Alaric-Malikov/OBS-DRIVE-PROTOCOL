@echo off
:: ============================================================
:: open_chrome.bat
:: Usage: open_chrome.bat <URL>
:: Opens Chrome to the given URL. Falls back to the default
:: browser if Chrome is not found.
:: ============================================================
setlocal

set URL=%~1
if "%URL%"=="" set URL=https://YOUR-URL-HERE.com

:: Common Chrome install paths
set CHROME_PATHS=^
    "%ProgramFiles%\Google\Chrome\Application\chrome.exe" ^
    "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" ^
    "%LocalAppData%\Google\Chrome\Application\chrome.exe"

for %%P in (%CHROME_PATHS%) do (
    if exist %%P (
        echo [Launcher] Launching Chrome from %%P
        start "" %%P "%URL%"
        exit /b 0
    )
)

:: Chrome not found — fall back to default browser
echo [Launcher] Chrome not found. Opening with default browser...
start "" "%URL%"

endlocal
