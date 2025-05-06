#!/bin/bash
set -e

# Update the environment in the running API container
docker compose -f docker/docker-compose.yml -f docker/docker-compose.override.yml exec api bash -c 'echo "CELERY_RESULT_BACKEND=redis://redis:6379/0" >> /app/.env'

echo "Added CELERY_RESULT_BACKEND to API container environment" 