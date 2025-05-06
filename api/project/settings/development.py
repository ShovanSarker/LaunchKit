"""
Development settings for LaunchKit.
"""

from .base import *

# Debug settings
DEBUG = True

# Development apps
INSTALLED_APPS += ["debug_toolbar"]

# Development middleware
MIDDLEWARE = ["debug_toolbar.middleware.DebugToolbarMiddleware"] + MIDDLEWARE

# Debug toolbar settings
INTERNAL_IPS = ["127.0.0.1"]

# Email settings - use console backend for development
EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"

# Disable security features in development
SECURE_SSL_REDIRECT = False
SESSION_COOKIE_SECURE = False
CSRF_COOKIE_SECURE = False 