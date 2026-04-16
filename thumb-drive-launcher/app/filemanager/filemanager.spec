# -*- mode: python ; coding: utf-8 -*-
"""
PyInstaller spec for the Django file manager.
Run:  pyinstaller filemanager.spec --noconfirm
Output: dist/filemanager/filemanager.exe  (one-folder mode for reliability)
"""
import os
from PyInstaller.utils.hooks import collect_data_files, collect_submodules

block_cipher = None

# ── Collect Django data files (templates, locale, management commands) ────────
django_datas = collect_data_files("django")

# ── Collect the browser app's templates ──────────────────────────────────────
browser_templates = [
    (
        os.path.join("browser", "templates"),
        os.path.join("browser", "templates"),
    )
]

a = Analysis(
    ["run_server.py"],
    pathex=["."],
    binaries=[],
    datas=django_datas + browser_templates,
    hiddenimports=[
        "django.template.defaulttags",
        "django.template.defaultfilters",
        "django.template.loader_tags",
        "django.contrib.staticfiles",
        "django.contrib.contenttypes",
        "django.contrib.auth",
        "django.contrib.messages",
        "django.contrib.sessions",
        *collect_submodules("django"),
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=["tkinter", "test", "unittest"],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="filemanager",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=True,  # keep console so start.bat can see output
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name="filemanager",
)
