"""
Settings module for LaunchKit.

This module selects the appropriate settings file based on the DJANGO_ENV environment variable.
"""

import os

# Default to development settings
environment = os.environ.get("DJANGO_ENV", "development")

if environment == "production":
    from .production import *
elif environment == "staging":
    from .staging import *
else:
    from .development import * 