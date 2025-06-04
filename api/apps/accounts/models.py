"""
Models for the accounts app.
"""

from django.db import models
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver

from apps.core.models import TimeStampedModel, UUIDModel


class Profile(UUIDModel, TimeStampedModel):
    """
    User profile model that extends the built-in User model.
    """
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    bio = models.TextField(max_length=500, blank=True)
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)
    phone_number = models.CharField(max_length=20, blank=True)
    
    def __str__(self):
        return f"{self.user.username}'s Profile"


@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    """
    Signal handler to create a profile when a user is created.
    """
    if created:
        Profile.objects.create(user=instance)


@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    """
    Signal handler to save a profile when a user is saved.
    """
    try:
        # Check if profile exists before saving
        if hasattr(instance, 'profile'):
            instance.profile.save()
    except User.profile.RelatedObjectDoesNotExist:
        # Create profile if it doesn't exist
        Profile.objects.create(user=instance)


class LoginAttempt(TimeStampedModel):
    """
    Model to track login attempts for security monitoring.
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True)
    username = models.CharField(max_length=150)
    ip_address = models.GenericIPAddressField()
    user_agent = models.TextField(blank=True)
    successful = models.BooleanField(default=False)
    
    def __str__(self):
        status = "successful" if self.successful else "failed"
        return f"{status} login attempt by {self.username} from {self.ip_address}" 