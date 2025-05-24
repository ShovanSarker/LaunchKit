"""
Custom email backend for development that stores emails in the database.
"""

from django.core.mail.backends.smtp import EmailBackend as SMTPBackend
from django.core.mail.backends.console import EmailBackend as ConsoleBackend
from django.conf import settings
from django.utils import timezone


class DevEmailBackend(ConsoleBackend):
    """
    Email backend for development that prints to console.
    """
    
    def send_messages(self, email_messages):
        """
        Print emails to console in development.
        """
        return super().send_messages(email_messages) 