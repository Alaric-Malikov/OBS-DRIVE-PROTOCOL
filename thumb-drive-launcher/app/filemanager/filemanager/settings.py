import os
import sys
from pathlib import Path

# When running as a PyInstaller frozen binary, __file__ lives inside
# the temporary _MEIPASS extraction dir.  Walk up from there to find
# the templates and app packages.
if getattr(sys, "frozen", False):
    # _MEIPASS is the root of the extracted bundle
    _BUNDLE_DIR = Path(sys._MEIPASS)  # type: ignore[attr-defined]
else:
    _BUNDLE_DIR = Path(__file__).resolve().parent.parent

BASE_DIR = _BUNDLE_DIR

SECRET_KEY = 'thumb-drive-local-only-not-for-production'

DEBUG = True

ALLOWED_HOSTS = ['127.0.0.1', 'localhost', '*']

INSTALLED_APPS = [
    'django.contrib.staticfiles',
    'browser',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.middleware.common.CommonMiddleware',
]

ROOT_URLCONF = 'filemanager.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        # Explicit path works correctly inside PyInstaller bundles
        # (APP_DIRS=True can fail when the app directory is inside _MEIPASS)
        'DIRS': [BASE_DIR / 'browser' / 'templates'],
        'APP_DIRS': False,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
            ],
        },
    },
]

WSGI_APPLICATION = 'filemanager.wsgi.application'

STATIC_URL = '/static/'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# The root directory the file manager is allowed to browse.
# Set via DRIVE_ROOT environment variable from start.bat / start.sh.
# Falls back to the drive letter of the bundle (Windows) or /media (Linux).
def _default_drive_root() -> str:
    if sys.platform == 'win32':
        drive = Path(sys.executable).drive if getattr(sys, 'frozen', False) \
                else Path(__file__).resolve().drive
        return drive + '\\'
    return '/media'

DRIVE_ROOT = Path(os.environ.get('DRIVE_ROOT', _default_drive_root()))
