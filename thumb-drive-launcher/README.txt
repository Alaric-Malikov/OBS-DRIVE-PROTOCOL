============================================================
  THUMB DRIVE LAUNCHER - Setup & Usage Guide
============================================================

WHAT THIS DOES:
  When you plug in the drive, a popup appears. Click "Run program"
  (or double-click launcher\start.bat manually). It will:
    1. Start a local web file manager (Django)
    2. Open Chrome showing your drive's files as a web app
    3. Let you browse, upload, download, rename & delete files
       directly on the drive — through the browser

============================================================
FOLDER STRUCTURE ON YOUR THUMB DRIVE
============================================================

<drive>:\
  autorun.inf              ← triggers AutoPlay popup on plug-in
  launcher\
    start.bat              ← MAIN LAUNCHER — run this
    stop.bat               ← run before removing the drive
    install_deps.bat       ← run ONCE on first setup
    wait_for_server.bat    ← helper (auto-used by start.bat)
    open_chrome.bat        ← helper (auto-used by start.bat)
  app\
    filemanager\           ← the Django web file manager
      manage.py
      requirements.txt
      filemanager\         ← Django project settings
      browser\             ← file browser app (views, templates)

============================================================
FIRST-TIME SETUP
============================================================

1. COPY FILES
   Copy everything here to the ROOT of your thumb drive.

2. INSTALL DEPENDENCIES (once per machine)
   Double-click: launcher\install_deps.bat
   This installs Django via pip. Requires Python 3 + internet access.

   TIP: For a fully offline/portable setup, bundle a Python
   embeddable distribution at: app\python\python.exe
   start.bat will find it automatically.

3. THAT'S IT
   From now on, just plug in and click "Run program" in the AutoPlay
   popup — or double-click launcher\start.bat directly.

============================================================
ADDING YOUR OWN PROGRAM
============================================================

Open launcher\start.bat and find the section labeled:
  "STEP 4: (Optional) Run your own custom program"

Uncomment and edit the line there to launch your own app
alongside the file manager.

============================================================
WHAT FILES THE FILE MANAGER CAN SEE
============================================================

By default, the file manager shows the entire drive root.
To restrict it to a specific folder, open launcher\start.bat
and change this line:

  set DRIVE_ROOT=%DRIVE%\

Example — only show an "uploads" folder:
  set DRIVE_ROOT=%DRIVE%\uploads

============================================================
AUTOPLAY / AUTORUN NOTES
============================================================

Windows 7+ disables AutoRun for security. You will see an
AutoPlay dialog — choose "Run program" or "Open folder".

If no dialog appears, just open the drive in File Explorer
and double-click: launcher\start.bat

============================================================
STOPPING / SAFE REMOVAL
============================================================

1. Double-click launcher\stop.bat
2. Wait for "You may safely remove the drive"
3. Use Windows "Safely Remove Hardware" tray icon

============================================================
REQUIREMENTS ON TARGET MACHINE
============================================================

- Windows 7 or later
- Python 3.8+ installed (or bundled at app\python\python.exe)
- Google Chrome (recommended; falls back to default browser)
- Internet access (first time only, to install Django via pip)
