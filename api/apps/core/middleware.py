"""
Middleware for LaunchKit core functionality.
"""

import uuid
import time
import logging
import json
import traceback
from django.conf import settings
from django.utils.deprecation import MiddlewareMixin

logger = logging.getLogger(__name__)


class RequestIDMiddleware(MiddlewareMixin):
    """
    Middleware that adds a unique request ID to each request.
    """
    
    def process_request(self, request):
        """
        Generate a unique request ID and attach it to the request object.
        """
        request_id = str(uuid.uuid4())
        request.request_id = request_id
        return None


class JSONLoggingMiddleware(MiddlewareMixin):
    """
    Middleware that logs request and response information in JSON format.
    """
    
    def process_request(self, request):
        """
        Log request information and attach start time to the request.
        """
        request.start_time = time.time()
        
        # Don't log health check requests
        if request.path.startswith('/api/health'):
            return None
        
        # Don't log static/media requests
        if request.path.startswith(('/static/', '/media/')):
            return None
        
        log_data = {
            'request_id': getattr(request, 'request_id', str(uuid.uuid4())),
            'method': request.method,
            'path': request.path,
            'query_params': dict(request.GET),
            'remote_addr': request.META.get('REMOTE_ADDR', ''),
            'user_agent': request.META.get('HTTP_USER_AGENT', ''),
            'user_id': request.user.id if hasattr(request, 'user') and request.user.is_authenticated else None,
        }
        
        # In development, also log request body
        if settings.DEBUG and request.body:
            try:
                log_data['body'] = json.loads(request.body)
            except json.JSONDecodeError:
                log_data['body'] = request.body.decode('utf-8', errors='replace')
        
        logger.info('Request started', extra=log_data)
        return None
    
    def process_response(self, request, response):
        """
        Log response information including timing.
        """
        # Don't log health check responses
        if request.path.startswith('/api/health'):
            return response
        
        # Don't log static/media responses
        if request.path.startswith(('/static/', '/media/')):
            return response
        
        # Calculate request duration
        duration = 0
        if hasattr(request, 'start_time'):
            duration = time.time() - request.start_time
        
        log_data = {
            'request_id': getattr(request, 'request_id', str(uuid.uuid4())),
            'method': request.method,
            'path': request.path,
            'status_code': response.status_code,
            'duration_ms': int(duration * 1000),
            'user_id': request.user.id if hasattr(request, 'user') and request.user.is_authenticated else None,
        }
        
        # In development, include response content for errors
        if settings.DEBUG and response.status_code >= 400:
            try:
                log_data['response'] = json.loads(response.content)
            except json.JSONDecodeError:
                log_data['response'] = response.content.decode('utf-8', errors='replace')
            
            # Include traceback for 500 errors
            if response.status_code >= 500:
                log_data['traceback'] = traceback.format_exc()
        
        # Log at different levels based on status code
        if response.status_code >= 500:
            logger.error('Request failed', extra=log_data)
        elif response.status_code >= 400:
            logger.warning('Request error', extra=log_data)
        else:
            logger.info('Request completed', extra=log_data)
        
        return response


class ExceptionLoggingMiddleware(MiddlewareMixin):
    """
    Middleware that logs unhandled exceptions in detail.
    """
    
    def process_exception(self, request, exception):
        """
        Log unhandled exceptions with full traceback in development.
        """
        log_data = {
            'request_id': getattr(request, 'request_id', str(uuid.uuid4())),
            'method': request.method,
            'path': request.path,
            'exception': str(exception),
            'exception_type': exception.__class__.__name__,
            'traceback': traceback.format_exc(),
        }
        
        logger.error('Unhandled exception', extra=log_data)
        return None 