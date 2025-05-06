"""
Admin configuration for the accounts app.
"""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User

from apps.accounts.models import Profile, LoginAttempt


class ProfileInline(admin.StackedInline):
    """
    Inline admin for the Profile model.
    """
    model = Profile
    can_delete = False
    verbose_name_plural = 'Profile'
    fk_name = 'user'


class UserAdmin(BaseUserAdmin):
    """
    Custom user admin that includes the Profile inline.
    """
    inlines = (ProfileInline, )
    list_display = ('username', 'email', 'first_name', 'last_name', 'is_staff', 'is_active')
    list_filter = ('is_staff', 'is_superuser', 'is_active')


class LoginAttemptAdmin(admin.ModelAdmin):
    """
    Admin for the LoginAttempt model.
    """
    list_display = ('username', 'ip_address', 'successful', 'created_at')
    list_filter = ('successful', 'created_at')
    search_fields = ('username', 'ip_address', 'user_agent')
    readonly_fields = ('username', 'ip_address', 'user_agent', 'successful', 'created_at', 'updated_at')
    date_hierarchy = 'created_at'


# Re-register UserAdmin
admin.site.unregister(User)
admin.site.register(User, UserAdmin)
admin.site.register(LoginAttempt, LoginAttemptAdmin) 