# Celery Setup Guide

This guide explains how Celery is set up and configured in the LaunchKit project.

## Overview

Celery is used for handling asynchronous tasks and scheduled jobs in the project. The setup includes:
- Celery workers for processing tasks
- Celery Beat for scheduled tasks
- Redis for result backend
- RabbitMQ for message broker

## Configuration

### Basic Setup

The Celery application is configured in `project/celery.py`:

```python
import os
from celery import Celery
from django.conf import settings

# Set the default Django settings module
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "project.settings")

app = Celery("project")

# Configure Celery using Django settings
app.config_from_object("django.conf:settings", namespace="CELERY")

# Auto-discover tasks from all installed apps
app.autodiscover_tasks()

# Configure Celery Beat schedule
app.conf.beat_schedule = {
    "cleanup_expired_sessions": {
        "task": "project.tasks.cleanup_expired_sessions",
        "schedule": 86400.0,  # once every 24 hours
    },
}
```

### Settings

The main Celery settings are defined in `project/settings/base.py`:

```python
# Celery Configuration
CELERY_BROKER_URL = env("CELERY_BROKER_URL")
CELERY_RESULT_BACKEND = env("CELERY_RESULT_BACKEND", default=env("REDIS_URL"))
CELERY_ACCEPT_CONTENT = ["json"]
CELERY_TASK_SERIALIZER = "json"
CELERY_RESULT_SERIALIZER = "json"
CELERY_TIMEZONE = TIME_ZONE

# Task Time Limits
CELERY_TASK_TIME_LIMIT = 60 * 5  # 5 minutes
CELERY_TASK_SOFT_TIME_LIMIT = 60 * 3  # 3 minutes

# Worker Settings
CELERY_WORKER_PREFETCH_MULTIPLIER = 1
CELERY_WORKER_MAX_TASKS_PER_CHILD = 100
```

### Scheduled Tasks

Scheduled tasks are configured in `apps/celerybeat-schedule.py`:

```python
from celery.schedules import crontab
from datetime import timedelta

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
```

## Development Setup

1. Install dependencies:
   ```bash
   pip install -r requirements/dev.txt
   ```

2. Set environment variables in `api/.env`:
   ```
   CELERY_BROKER_URL=amqp://localhost:5672
   REDIS_URL=redis://localhost:6379/0
   CELERY_RESULT_BACKEND=redis://localhost:6379/0
   ```

3. Run Celery worker:
   ```bash
   celery -A project worker --loglevel=info
   ```

4. Run Celery Beat (if needed):
   ```bash
   celery -A project beat --loglevel=info
   ```

## Docker Setup

The project includes Docker configuration for Celery services in `docker/docker-compose.yml`:

```yaml
  # Celery Worker
  worker:
    build:
      context: ../api
      dockerfile: Dockerfile
    volumes:
      - ../api:/app
    env_file:
      - ../api/.env
    environment:
      - DJANGO_SETTINGS_MODULE=project.settings.development
    depends_on:
      - postgres
      - redis
      - rabbitmq
    command: celery -A project worker --loglevel=info

  # Celery Beat Scheduler
  scheduler:
    build:
      context: ../api
      dockerfile: Dockerfile
    volumes:
      - ../api:/app
    env_file:
      - ../api/.env
    environment:
      - DJANGO_SETTINGS_MODULE=project.settings.development
    depends_on:
      - postgres
      - redis
      - rabbitmq
    command: celery -A project beat --loglevel=info
```

## Monitoring

### Logging

Celery logs are configured in `project/settings/base.py`:

```python
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'json': {
            '()': 'pythonjsonlogger.jsonlogger.JsonFormatter',
            'format': '%(asctime)s %(levelname)s %(name)s %(message)s',
        },
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'celery': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': 'logs/worker.log',
            'formatter': 'json',
            'maxBytes': 1024 * 1024 * 100,  # 100 MB
            'backupCount': 2,
        },
    },
    'loggers': {
        'celery': {
            'handlers': ['celery', 'console'],
            'level': 'INFO',
            'propagate': True,
        },
    },
}
```

### Sentry Integration

In production (`project/settings/production.py`), Celery is integrated with Sentry for error tracking:

```python
if env("SENTRY_DSN", default=None):
    import sentry_sdk
    from sentry_sdk.integrations.django import DjangoIntegration
    from sentry_sdk.integrations.celery import CeleryIntegration
    from sentry_sdk.integrations.redis import RedisIntegration

    sentry_sdk.init(
        dsn=env("SENTRY_DSN"),
        integrations=[
            DjangoIntegration(),
            CeleryIntegration(),
            RedisIntegration(),
        ],
        traces_sample_rate=0.1,
        send_default_pii=False,
        environment=env("DJANGO_ENV"),
    )
```

## Best Practices

1. Use `@shared_task` decorator for tasks
2. Set appropriate task timeouts and retry policies
3. Use task routing for specific task types (e.g., emails)
4. Monitor worker health and queue sizes
5. Use task idempotency where possible

## Common Issues

1. **Connection Errors**: Check RabbitMQ connection and credentials
2. **Task Timeouts**: Review task execution time and timeout settings
3. **Queue Buildup**: Monitor queue sizes and worker capacity
4. **Memory Leaks**: Watch for memory usage in long-running workers

## Security

1. Use SSL for broker connections in production
2. Set appropriate user permissions on RabbitMQ vhosts
3. Never store sensitive data in task parameters
4. Monitor worker access and execution logs 