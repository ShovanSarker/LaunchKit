"""
Admin configuration for core app.
"""

from django.contrib import admin
from django.utils.html import format_html, escape
from django.utils.safestring import mark_safe
from apps.core.models import Email


@admin.register(Email)
class EmailAdmin(admin.ModelAdmin):
    """
    Admin configuration for Email model.
    """
    list_display = ('subject', 'from_email', 'to_emails', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('subject', 'from_email', 'to_emails', 'body', 'html_body')
    readonly_fields = ('created_at', 'html_preview')
    
    fieldsets = (
        (None, {
            'fields': ('subject', 'from_email', 'to_emails')
        }),
        ('Additional Recipients', {
            'fields': ('cc_emails', 'bcc_emails'),
            'classes': ('collapse',)
        }),
        ('Content', {
            'fields': ('body',),
            'description': 'Enter the plain text content of the email.'
        }),
        ('Preview', {
            'fields': ('html_preview',),
            'description': 'Preview of how the email will appear to recipients.',
            'classes': ('wide',)
        }),
        ('Metadata', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        })
    )
    
    def html_preview(self, obj):
        """
        Display the email preview in an isolated iframe.
        """
        if obj.html_body:
            escaped_html = escape(obj.html_body)
            return mark_safe(
                '<div style="width: 100%; display: flex; justify-content: center;">'
                f'<iframe srcdoc="{escaped_html}" '
                'style="width: 800px; height: 800px; border: none; background: transparent;">'
                '</iframe>'
                '</div>'
            )
        return "No HTML preview available"
    html_preview.short_description = " " 