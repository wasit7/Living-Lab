import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = 'workshop-fullstack-secret-key'
DEBUG = True
ALLOWED_HOSTS = ['*']

# กำหนดชนิดของ primary key เริ่มต้นเพื่อลดคำเตือน
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework', # เพิ่ม Django REST Framework
    'corsheaders',    # สำหรับอนุญาตให้ Frontend (React) เรียก API ได้
    'api',            # แอพของเรา
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware', # สำคัญสำหรับการทำ API
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'core.urls'
WSGI_APPLICATION = 'core.wsgi.application'

# ตั้งค่าให้เชื่อมต่อไปยัง Container ชื่อ 'db' (Postgres)
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'workshop_db',
        'USER': 'workshop_user',
        'PASSWORD': 'workshop_password',
        'HOST': 'db',
        'PORT': '5432',
    }
}

CORS_ALLOW_ALL_ORIGINS = True # อนุญาตให้ทุก Domain เรียก API ได้ (เพื่อความง่ายใน Workshop)
STATIC_URL = 'static/'

# ตั้งค่า templates สำหรับ django admin
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]
