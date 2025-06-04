import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration
from sentry_sdk.integrations.celery import CeleryIntegration
from sentry_sdk.integrations.logging import LoggingIntegration
from .base import *

# Sentry Configuration
SENTRY_DSN = env('SENTRY_DSN', default='')
SENTRY_RELEASE = env('SENTRY_RELEASE', default='development')

if SENTRY_DSN:
    sentry_logging = LoggingIntegration(
        level=logging.INFO,
        event_level=logging.ERROR
    )
    
    sentry_sdk.init(
        dsn=SENTRY_DSN,
        integrations=[
            sentry_logging,
            DjangoIntegration(),
            CeleryIntegration()
        ],
        release=SENTRY_RELEASE,
        send_default_pii=True,
        traces_sample_rate=0.1,
    )

# Celery Production Settings
CELERY_TASK_ALWAYS_EAGER = False
CELERY_TASK_STORE_EAGER_RESULT = False
CELERY_TASK_REMOTE_TRACEBACKS = True
CELERY_SEND_TASK_ERROR_EMAILS = True

# SSL/TLS Settings for Celery Broker
CELERY_BROKER_USE_SSL = {
    'keyfile': '/etc/ssl/private/worker-key.pem',
    'certfile': '/etc/ssl/certs/worker-cert.pem',
    'ca_certs': '/etc/ssl/certs/ca-cert.pem',
    'cert_reqs': ssl.CERT_REQUIRED
} 