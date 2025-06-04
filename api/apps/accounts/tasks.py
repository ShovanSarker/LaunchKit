"""
Celery tasks for the accounts app.
"""

from celery import shared_task
from django.conf import settings
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.contrib.auth import get_user_model
from django.urls import reverse


@shared_task
def send_password_reset_email(user_id, token, uid):
    """
    Send password reset email asynchronously.
    """
    User = get_user_model()
    try:
        user = User.objects.get(pk=user_id)
        
        # Build the reset URL (frontend URL)
        reset_url = f"{settings.FRONTEND_URL}/auth/reset-password/{uid}/{token}/"
        
        # Render email template
        context = {
            'user': user,
            'reset_url': reset_url,
            'site_name': settings.PROJECT_NAME,
        }
        
        email_html_message = render_to_string('email/password_reset_email.html', context)
        email_plaintext_message = render_to_string('email/password_reset_email.txt', context)
        
        # Send email
        send_mail(
            subject=f"Password Reset for {settings.PROJECT_NAME}",
            message=email_plaintext_message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
            html_message=email_html_message,
            fail_silently=False,
        )
        
        return True
    except User.DoesNotExist:
        return False 