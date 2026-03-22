============================================================
  THUMB DRIVE LAUNCHER - Setup & Usage Guide
============================================================

FOLDER STRUCTURE ON YOUR THUMB DRIVE:
--------------------------------------
<drive>:\
  autorun.inf          <-- tells Windows to auto-run on plug-in
  launcher\
    start.bat          <-- main launcher (auto-run target)
    stop.bat           <-- run this before removing the drive
    wait_for_server.bat  <-- helper: waits for Django to start
    open_chrome.bat    <-- helper: opens Chrome to your URL
    icon.ico           <-- (optional) drive icon shown in Explorer
  app\
    django\            <-- put your Django project here
      manage.py
      ...
    my_program\        <-- (optional) your custom file system program
      ...

============================================================
SETUP STEPS
============================================================

1. COPY FILES TO YOUR THUMB DRIVE
   - Copy everything in this folder to the ROOT of your thumb drive.
   - Your drive should look like the structure above.

2. SET YOUR URL
   Open launcher\start.bat and find this line:
       set TARGET_URL=https://YOUR-URL-HERE.com
   Replace it with your actual URL.

3. SET YOUR DJANGO DIRECTORY
   In launcher\start.bat, verify this line points to your Django project:
       set DJANGO_DIR=%APP_DIR%\django
   If your Django project is in a different subfolder under \app\, update it.

4. (OPTIONAL) ADD YOUR CUSTOM PROGRAM
   In launcher\start.bat, find the commented-out section:
       :: start "" "%APP_DIR%\my_program\my_program.exe"
   Uncomment and edit it to launch your file system program.

5. (OPTIONAL) ADD A DRIVE ICON
   Place a file named icon.ico inside the launcher\ folder.
   Windows will use it as the drive's icon in File Explorer.

============================================================
AUTORUN NOTES
============================================================

- AutoRun is DISABLED by default on Windows 7 and later for
  security reasons. Users will see an AutoPlay dialog asking
  what to do. They can choose "Run program" or similar.

- To enable full AutoRun (not recommended for shared PCs):
  Use Group Policy (gpedit.msc) or registry:
    HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\IniFileMapping\Autorun.inf
  Set value to: @SYS:DoesNotExist

- The safest approach: instruct users to open the drive in
  File Explorer and double-click launcher\start.bat manually
  if AutoPlay does not appear.

============================================================
STOPPING / SAFE REMOVAL
============================================================

Before unplugging the drive:
1. Double-click launcher\stop.bat
2. Wait for the "You may safely remove the drive" message
3. Use Windows "Safely Remove Hardware" and eject the drive

============================================================
REQUIREMENTS ON TARGET MACHINE
============================================================

- Windows 7 or later
- Python 3.x installed (for Django)
- Google Chrome installed (recommended; falls back to default browser)
- Your Django app's dependencies installed (pip install -r requirements.txt)

  TIP: For a fully portable setup, bundle a Python embeddable
  distribution inside your app\ folder and point PYTHON in
  start.bat to that local python.exe instead.
