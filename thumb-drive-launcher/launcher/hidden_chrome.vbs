' hidden_chrome.vbs
' Launches Chrome in headless mode to silently load a URL.
' The window style 0 means completely hidden — no taskbar, no UI.
' Called by background_launcher.bat via wscript.

Dim url
url = WScript.Arguments(0)

Dim chromePaths(2)
chromePaths(0) = "C:\Program Files\Google\Chrome\Application\chrome.exe"
chromePaths(1) = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"

Dim fso, chromePath, found
Set fso = CreateObject("Scripting.FileSystemObject")
found = False

Dim i
For i = 0 To 1
    If fso.FileExists(chromePaths(i)) Then
        chromePath = chromePaths(i)
        found = True
        Exit For
    End If
Next

' Check LocalAppData path
If Not found Then
    Dim localApp
    localApp = CreateObject("WScript.Shell").ExpandEnvironmentStrings("%LOCALAPPDATA%")
    Dim localChrome
    localChrome = localApp & "\Google\Chrome\Application\chrome.exe"
    If fso.FileExists(localChrome) Then
        chromePath = localChrome
        found = True
    End If
End If

If found Then
    Dim cmd
    cmd = """" & chromePath & """ --headless=old --disable-gpu --no-sandbox """ & url & """"
    ' Window style 0 = completely hidden
    CreateObject("WScript.Shell").Run cmd, 0, False
Else
    ' Chrome not found — fall back to a silent PowerShell web request (pings the URL)
    Dim psCmd
    psCmd = "powershell -NoProfile -WindowStyle Hidden -Command ""Invoke-WebRequest -Uri '" & url & "' -UseBasicParsing -TimeoutSec 30 | Out-Null"""
    CreateObject("WScript.Shell").Run psCmd, 0, False
End If
