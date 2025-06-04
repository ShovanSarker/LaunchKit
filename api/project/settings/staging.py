"""
Staging settings for LaunchKit.
"""

from .production import *

# Staging-specific settings
DEBUG = env.bool("DEBUG", default=False)

# Allow more detailed error reporting in staging
LOGGING["loggers"]["django"]["level"] = "DEBUG"

# Lower rate limits for staging
REST_FRAMEWORK["DEFAULT_THROTTLE_RATES"] = {
    "auth": "10/min",  # More lenient for testing
}

# Override Sentry environment
if env("SENTRY_DSN", default=None):
    import sentry_sdk
    sentry_sdk.init(
        dsn=env("SENTRY_DSN"),
        environment="staging",
    ) 