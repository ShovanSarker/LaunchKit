"""
Email utilities for LaunchKit.
"""

from typing import List, Optional
from django.core.mail import send_mail as django_send_mail
from django.conf import settings
from django.utils import timezone
from apps.core.models import Email


def send_email(
    subject: str,
    message: str,
    to_emails: List[str],
    from_email: Optional[str] = None,
    html_message: Optional[str] = None,
    cc_emails: Optional[List[str]] = None,
    bcc_emails: Optional[List[str]] = None,
) -> bool:
    """
    Send an email and store it in the database.
    
    Args:
        subject: The subject of the email
        message: The plain text message
        to_emails: List of recipient email addresses
        from_email: Sender's email address (defaults to DEFAULT_FROM_EMAIL)
        html_message: Optional HTML version of the message
        cc_emails: Optional list of CC recipients
        bcc_emails: Optional list of BCC recipients
    
    Returns:
        bool: True if the email was sent successfully, False otherwise
    """
    if from_email is None:
        from_email = settings.DEFAULT_FROM_EMAIL
        
    try:
        # Send the email using Django's send_mail
        sent = django_send_mail(
            subject=subject,
            message=message,
            from_email=from_email,
            recipient_list=to_emails,
            html_message=html_message,
            fail_silently=False,
        )
        
        # Store the email in the database regardless of whether it was sent
        # This helps track failed attempts in development
        Email.objects.create(
            subject=subject,
            body=message,
            html_body=html_message,
            from_email=from_email,
            to_emails=', '.join(to_emails),
            cc_emails=', '.join(cc_emails or []),
            bcc_emails=', '.join(bcc_emails or []),
            created_at=timezone.now()
        )
        
        return sent
        
    except Exception as e:
        # Log the error and store the failed attempt
        # In development, this will help debug email issues
        Email.objects.create(
            subject=f"[FAILED] {subject}",
            body=f"Error sending email: {str(e)}\n\nOriginal message:\n{message}",
            html_body=html_message,
            from_email=from_email,
            to_emails=', '.join(to_emails),
            cc_emails=', '.join(cc_emails or []),
            bcc_emails=', '.join(bcc_emails or []),
            created_at=timezone.now()
        )
        
        # Re-raise the exception to be handled by the caller
        raise 