"""
Entry point used by PyInstaller to produce filemanager.exe.

Usage (from start.bat):
    filemanager.exe 127.0.0.1:8000

The DRIVE_ROOT environment variable tells the file manager which
folder to expose. start.bat sets this before launching the exe.
"""
import sys
import os

# When running as a PyInstaller bundle, __file__ is inside a temp dir.
# We need Django to find the app's source files (templates, migrations, etc.)
# which are stored alongside the exe in the _MEIPASS bundle.
if getattr(sys, "frozen", False):
    BASE_DIR = sys._MEIPASS  # type: ignore[attr-defined]
else:
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))

sys.path.insert(0, BASE_DIR)
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "filemanager.settings")

from django.core.management import execute_from_command_line  # noqa: E402

port_arg = sys.argv[1] if len(sys.argv) > 1 else "127.0.0.1:8000"
execute_from_command_line(["manage.py", "runserver", port_arg, "--noreload"])
