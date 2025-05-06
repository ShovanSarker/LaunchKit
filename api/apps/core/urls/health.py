"""
Health check URLs for LaunchKit.
"""

from django.urls import path
from django.http import JsonResponse
from django.db import connections
from django.db.utils import OperationalError
from redis.exceptions import RedisError
import redis
import os
import datetime


def health_check(request):
    """
    Health check endpoint for monitoring and load balancers.
    """
    # Check database connection
    db_healthy = True
    try:
        connections['default'].cursor()
    except OperationalError:
        db_healthy = False
    
    # Check Redis connection
    redis_healthy = True
    try:
        redis_url = os.environ.get('REDIS_URL', 'redis://redis:6379/0')
        redis_client = redis.from_url(redis_url)
        redis_client.ping()
    except RedisError:
        redis_healthy = False
    
    # Overall health status
    status = 'healthy' if db_healthy and redis_healthy else 'unhealthy'
    status_code = 200 if status == 'healthy' else 503
    
    response_data = {
        'status': status,
        'timestamp': datetime.datetime.utcnow().isoformat(),
        'components': {
            'database': 'healthy' if db_healthy else 'unhealthy',
            'redis': 'healthy' if redis_healthy else 'unhealthy',
        }
    }
    
    return JsonResponse(response_data, status=status_code)


urlpatterns = [
    path('', health_check, name='health_check'),
] 