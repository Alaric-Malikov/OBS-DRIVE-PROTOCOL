import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

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
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
            ],
        },
    },
]

WSGI_APPLICATION = 'filemanager.wsgi.application'

STATIC_URL = '/static/'

DEFAULT_AUTO_FIELD = 'django.db.backends.sqlite3'

# The root directory the file manager is allowed to browse.
# Set via DRIVE_ROOT environment variable from start.bat.
# Falls back to the drive root where this script lives.
_default_root = Path(__file__).resolve().drive + '\\'
DRIVE_ROOT = Path(os.environ.get('DRIVE_ROOT', _default_root))
