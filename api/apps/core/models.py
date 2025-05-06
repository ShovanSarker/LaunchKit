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