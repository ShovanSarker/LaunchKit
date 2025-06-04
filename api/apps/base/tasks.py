from celery import shared_task
from django.db import connections
from django.core.mail import send_mail
from django.conf import settings

@shared_task(
    queue='default',
    autoretry_for=(Exception,),
    retry_backoff=True,
    retry_kwargs={'max_retries': 3},
)
def check_db_connections():
    """Check the number of database connections and warn if too high."""
    for conn in connections.all():
        if conn.connection is not None:
            with conn.cursor() as cursor:
                cursor.execute('SELECT count(*) FROM pg_stat_activity')
                count = cursor.fetchone()[0]
                if count > settings.DB_CONNECTION_WARNING_THRESHOLD:
                    send_mail(
                        subject='High Database Connections Warning',
                        message=f'Current connection count: {count}',
                        from_email=settings.DEFAULT_FROM_EMAIL,
                        recipient_list=[admin[1] for admin in settings.ADMINS],
                    )
    return True

@shared_task(
    queue='emails',
    bind=True,
    autoretry_for=(Exception,),
    retry_backoff=True,
    retry_kwargs={'max_retries': 3},
)
def send_email_notification(self, subject, message, recipient_list):
    """Send email notification task."""
    try:
        send_mail(
            subject=subject,
            message=message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=recipient_list,
        )
        return True
    except Exception as exc:
        self.retry(exc=exc) 