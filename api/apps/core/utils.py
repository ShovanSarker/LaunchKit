"""
Utility functions for LaunchKit.
"""

import json
import logging
import structlog
from datetime import datetime
from django.conf import settings
from django.utils import timezone


class JSONFormatter(logging.Formatter):
    """
    Custom formatter that outputs logs as JSON.
    """
    
    def format(self, record):
        """
        Format the log record as JSON.
        """
        log_data = {
            'timestamp': datetime.utcnow().isoformat(),
            'level': record.levelname,
            'message': record.getMessage(),
            'logger': record.name,
            'module': record.module,
            'filename': record.filename,
            'lineno': record.lineno,
            'environment': settings.DJANGO_ENV,
        }
        
        # Add extra fields from the record
        if hasattr(record, 'request_id'):
            log_data['request_id'] = record.request_id
        
        # Add any extra attributes from the record
        for key, value in record.__dict__.items():
            if key not in ['args', 'asctime', 'created', 'exc_info', 'exc_text', 'filename',
                          'funcName', 'id', 'levelname', 'levelno', 'lineno', 'module',
                          'msecs', 'message', 'msg', 'name', 'pathname', 'process',
                          'processName', 'relativeCreated', 'stack_info', 'thread', 'threadName']:
                log_data[key] = value
        
        # Format exception info if present
        if record.exc_info:
            log_data['exc_info'] = self.formatException(record.exc_info)
        
        return json.dumps(log_data)


def setup_structlog():
    """
    Configure structlog for structured logging.
    """
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.JSONRenderer(),
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )


def get_client_ip(request):
    """
    Get the client IP address from the request.
    """
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip


def aware_now():
    """
    Return timezone-aware current datetime.
    """
    return timezone.now() 