============================================================
  THUMB DRIVE LAUNCHER - Setup & Usage Guide
  Supports: Windows 7+  |  Linux  |  ChromeOS
============================================================

WHAT THIS DOES:
  When you plug in the drive and run the launcher, it will:
    1. Start a local web file manager (Django)
    2. Open Chrome showing your drive's files as a web app
    3. Let you browse, upload, download, rename & delete files
       directly on the drive — through the browser
    4. Silently pre-warm the external Replit project in the
       background so it loads instantly when you open it

============================================================
FOLDER STRUCTURE ON YOUR THUMB DRIVE
============================================================

<drive root>\
  autorun.inf              <- Windows AutoPlay trigger
  README.txt               <- this file
  launcher\
    start.bat              <- Windows launcher
    stop.bat               <- Windows shutdown
    start.sh               <- Linux / ChromeOS launcher
    stop.sh                <- Linux / ChromeOS shutdown
    background_launcher.bat/.sh   <- Replit wake-up (auto)
    wait_for_server.bat/.sh       <- startup helper (auto)
    open_chrome.bat / open_browser.sh  <- browser helper (auto)
  app\
    filemanager\
      filemanager.exe      <- compiled Windows binary (no Python needed)
      filemanager          <- compiled Linux binary   (no Python needed)
      manage.py            <- fallback if binary missing
      requirements.txt


============================================================
STARTING THE LAUNCHER
============================================================

  WINDOWS
  -------
  Option A (easiest): Plug in drive -> AutoPlay popup ->
                      click "Launch Application"
  Option B:           Open the drive in File Explorer ->
                      double-click launcher\start.bat

  LINUX
  -----
  Open a terminal and run:
    bash /media/YOUR_USERNAME/DRIVE_NAME/launcher/start.sh

  Tip: Find your drive path with:  lsblk -o NAME,MOUNTPOINT

  CHROMEOS (Linux environment)
  ----------------------------
  1. Enable Linux (Settings -> Advanced -> Developers -> Linux)
  2. Open the Terminal app
  3. Find the drive mount — usually:
       /mnt/chromeos/removable/YOUR_DRIVE_NAME/
  4. Run:
       bash /mnt/chromeos/removable/YOUR_DRIVE_NAME/launcher/start.sh

  If prompted, allow the Linux environment to access your files
  (Settings -> Linux -> Manage shared folders).


============================================================
FIRST-TIME SETUP (if compiled binary is missing)
============================================================

  WINDOWS:  Run launcher\install_deps.bat  (installs Django via pip)
  LINUX:    sudo apt install python3 python3-pip curl
            pip3 install django
  CHROMEOS: Open Linux terminal:
            sudo apt install python3 python3-pip curl
            pip3 install django


============================================================
STOPPING / SAFE REMOVAL
============================================================

  WINDOWS:   Double-click launcher\stop.bat
  LINUX:     bash /path/to/drive/launcher/stop.sh
  CHROMEOS:  bash /mnt/chromeos/removable/DRIVE/launcher/stop.sh

  Then eject/unmount the drive normally.


============================================================
RESTRICTING WHICH FILES ARE VISIBLE
============================================================

  The file manager shows the entire drive by default.
  To restrict it to a subfolder:

  Windows — open launcher\start.bat and change:
    set DRIVE_ROOT=%DRIVE%\
  to:
    set DRIVE_ROOT=%DRIVE%\my-folder

  Linux/ChromeOS — open launcher\start.sh and change:
    DRIVE_ROOT="$(cd "$LAUNCHER_DIR/.." && pwd)"
  to:
    DRIVE_ROOT="/path/to/drive/my-folder"


============================================================
REQUIREMENTS ON TARGET MACHINE
============================================================

  WINDOWS
    - Windows 7 or later
    - Compiled filemanager.exe (included) — no Python needed
    - Fallback: Python 3.8+ if binary not present
    - Google Chrome (recommended; falls back to default browser)

  LINUX
    - Any modern Linux distro
    - Compiled filemanager binary (included) — no Python needed
    - Fallback: Python 3.8+ and Django if binary not present
    - curl  (for background wake-up polling)
    - Google Chrome, Chromium, or any browser via xdg-open

  CHROMEOS
    - ChromeOS with Linux environment enabled
    - Same requirements as Linux above
    - URLs open in the ChromeOS Chrome browser automatically
