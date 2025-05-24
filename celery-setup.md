# Celery Setup Guide

This guide explains how Celery is set up and configured in the SPP Backend Django project.

## Overview

Celery is used for handling asynchronous tasks and scheduled jobs in the project. The setup includes:
- Celery workers for processing tasks
- Celery Beat for scheduled tasks
- Flower for monitoring (optional)

## Configuration

### Basic Setup

The Celery application is configured in `apps/celery.py`:

```python
from celery import Celery

app = Celery("apps")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()
```

### Settings

The main Celery settings are defined in `settings/base.py`:

```python
# Celery Configuration
BROKER_URL = env("CELERY_BROKER_URL")

# Task Queues
exchange_default = Exchange("default")
CELERY_TASK_QUEUES = (
    Queue("default", exchange_default, routing_key="default"),
    Queue("emails", exchange_default, routing_key="emails"),
)

# Default Queue Settings
CELERY_TASK_DEFAULT_QUEUE = "default"
CELERY_TASK_DEFAULT_EXCHANGE_TYPE = "direct"
CELERY_TASK_DEFAULT_ROUTING_KEY = "default"

# Serialization
CELERY_ACCEPT_CONTENT = ["pickle", "json"]
CELERY_TASK_SERIALIZER = "json"

# Task Routing
CELERY_TASK_ROUTES = {
    "djmail.tasks.send_messages": {"exchange": "default", "routing_key": "emails"},
    "djmail.tasks.retry_send_messages": {"exchange": "default", "routing_key": "emails"},
}
```

### Scheduled Tasks

Scheduled tasks are configured in `settings/base.py` under `CELERY_BEAT_SCHEDULE`:

```python
CELERY_BEAT_SCHEDULE = {
    "warn-high-number-db-connections": {
        "task": "apps.base.tasks.warn_high_db_connections",
        "schedule": timedelta(hours=1),
        "options": {"expires": 60 * 30},
    },
    "import-harvest-clients": {
        "task": "apps.harvest.tasks.import_clients",
        "schedule": crontab(minute=0),
        "options": {"expires": 60 * 30},
    },
    # ... other scheduled tasks ...
}
```

## Deployment

The project uses Ansible for deployment and includes separate roles for:
- Celery workers (`roles/celery`)
- Celery Beat scheduler (`roles/celery-beat`)
- Flower monitoring (`roles/flower`)

### Worker Configuration

Workers can be configured with specific queues. For example, in production:
```
worker-001: emails queue
worker-002 to worker-005: default queue
```

### Environment Variables

Required environment variables:
- `CELERY_BROKER_URL`: URL for the message broker (RabbitMQ)
- `REDIS_URL`: For result backend (if used)
- Other Django settings as needed by tasks

## Monitoring

### Logging

Celery logs are configured to:
- Write to `logs/worker.log`
- Use JSON formatting
- Rotate logs (100MB max size, 2 backups)

### Sentry Integration

In production (`settings/live.py`), Celery is integrated with Sentry for error tracking:

```python
sentry_sdk.init(
    dsn=SENTRY_DSN,
    integrations=[sentry_logging, DjangoIntegration(), CeleryIntegration()],
    release=SENTRY_RELEASE,
    send_default_pii=True,
    traces_sample_rate=0.1,
)
```

## Development Setup

1. Install RabbitMQ
2. Set environment variables:
   ```
   CELERY_BROKER_URL=amqp://localhost:5672
   ```
3. Run Celery worker:
   ```bash
   celery --app apps worker --loglevel info
   ```
4. Run Celery Beat (if needed):
   ```bash
   celery --app apps beat --loglevel info
   ```

## Best Practices

1. Always specify task queue explicitly if not using default
2. Use task routing for specific task types (e.g., emails)
3. Set appropriate task timeouts and retry policies
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