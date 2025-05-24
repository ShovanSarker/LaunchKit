"""
Core models for LaunchKit.
"""

import uuid
from django.db import models
from django.utils import timezone


class TimeStampedModel(models.Model):
    """
    An abstract base class model that provides self-updating
    created and modified fields.
    """
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class UUIDModel(models.Model):
    """
    An abstract base class model that uses UUID as primary key.
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)

    class Meta:
        abstract = True


class SoftDeleteManager(models.Manager):
    """
    Manager for soft delete models that excludes deleted objects by default.
    """
    def get_queryset(self):
        return super().get_queryset().filter(deleted_at__isnull=True)


class SoftDeleteModel(models.Model):
    """
    An abstract base class model that provides soft delete functionality.
    """
    deleted_at = models.DateTimeField(null=True, blank=True)
    
    # Define managers
    objects = SoftDeleteManager()
    all_objects = models.Manager()
    
    class Meta:
        abstract = True
    
    def delete(self, using=None, keep_parents=False):
        """
        Soft delete the model instance by setting the deleted_at field.
        """
        self.deleted_at = timezone.now()
        self.save(update_fields=['deleted_at'])
        
    def hard_delete(self, using=None, keep_parents=False):
        """
        Hard delete the model instance from the database.
        """
        return super().delete(using=using, keep_parents=keep_parents)


class Email(models.Model):
    """
    Model to store emails sent during development.
    """
    from_email = models.EmailField()
    to_emails = models.TextField()
    cc_emails = models.TextField(blank=True)
    bcc_emails = models.TextField(blank=True)
    subject = models.CharField(max_length=255)
    body = models.TextField()
    html_body = models.TextField(null=True, blank=True)
    created_at = models.DateTimeField(default=timezone.now)
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Email'
        verbose_name_plural = 'Emails'
    
    def __str__(self):
        return f'{self.subject} - To: {self.get_recipients_display()} ({self.created_at:%Y-%m-%d %H:%M})'
    
    def get_recipients_display(self, max_length=50):
        """
        Get a formatted string of recipients, truncated if too long.
        """
        recipients = self.to_emails.split(',')[0].strip()
        more = len(self.to_emails.split(',')) - 1
        if more > 0:
            recipients += f' and {more} more'
        if len(recipients) > max_length:
            recipients = recipients[:max_length-3] + '...'
        return recipients
    
    def get_all_recipients(self):
        """
        Get a list of all recipients (To, CC, and BCC).
        """
        recipients = []
        if self.to_emails:
            recipients.extend(email.strip() for email in self.to_emails.split(','))
        if self.cc_emails:
            recipients.extend(email.strip() for email in self.cc_emails.split(','))
        if self.bcc_emails:
            recipients.extend(email.strip() for email in self.bcc_emails.split(','))
        return list(filter(None, recipients))
    
    def has_html_content(self):
        """
        Check if the email has HTML content.
        """
        return bool(self.html_body and self.html_body.strip()) 