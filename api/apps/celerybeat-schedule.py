from celery.schedules import crontab
from datetime import timedelta

# Scheduled tasks configuration
CELERYBEAT_SCHEDULE = {
    # Database monitoring task
    'check-database-connections': {
        'task': 'apps.base.tasks.check_db_connections',
        'schedule': timedelta(hours=1),
        'options': {
            'expires': 60 * 30,  # 30 minutes
            'queue': 'default'
        }
    },
    
    # Token cleanup task - runs at midnight
    'cleanup-expired-tokens': {
        'task': 'apps.auth.tasks.cleanup_expired_tokens',
        'schedule': crontab(hour=0, minute=0),
        'options': {
            'expires': 60 * 30,
            'queue': 'default'
        }
    },
    
    # Email queue monitoring - every 15 minutes
    'monitor-email-queue': {
        'task': 'apps.base.tasks.monitor_email_queue',
        'schedule': crontab(minute='*/15'),
        'options': {
            'expires': 60 * 10,
            'queue': 'emails'
        }
    }
}

# Beat settings
CELERYBEAT_MAX_LOOP_INTERVAL = 300  # 5 minutes
CELERYBEAT_SYNC_EVERY = 50  # Sync to disk every 50 updates 