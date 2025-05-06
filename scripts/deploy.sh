#!/bin/bash

set -e

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_DIR="${PROJECT_ROOT}/docker"

# Parse command line arguments
SKIP_PULL=false

for arg in "$@"; do
  case $arg in
    --skip-pull)
      SKIP_PULL=true
      shift
      ;;
    *)
      # Unknown option
      ;;
  esac
done

# Load environment variables
if [ -f "${PROJECT_ROOT}/.env" ]; then
  source "${PROJECT_ROOT}/.env"
fi

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print styled messages
print_message() {
  echo -e "${BLUE}[LaunchKit Deploy]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if the environment file exists
if [ ! -f "${PROJECT_ROOT}/.env" ]; then
  print_error "Environment file not found. Please run ./scripts/init.sh first."
  exit 1
fi

# For live environments, check DJANGO_ENV
if [ -n "$DJANGO_ENV" ] && [ "$DJANGO_ENV" != "development" ]; then
  print_message "Deploying to ${DJANGO_ENV} environment..."
elif [ "$DJANGO_ENV" == "development" ]; then
  print_message "Deploying to development environment..."
else
  print_error "DJANGO_ENV not set or invalid. Please run ./scripts/init.sh first."
  exit 1
fi

print_message "Starting deployment..."

# 1. Pull latest images (if not skipped)
if [ "$SKIP_PULL" = "false" ]; then
  print_message "Pulling latest Docker images..."
  docker compose -f "${DOCKER_DIR}/docker-compose.yml" -f "${DOCKER_DIR}/docker-compose.override.yml" pull
fi

# 2. Start core infrastructure services first
print_message "Starting infrastructure services (PostgreSQL, Redis, RabbitMQ)..."
docker compose -f "${DOCKER_DIR}/docker-compose.yml" -f "${DOCKER_DIR}/docker-compose.override.yml" up -d postgres redis rabbitmq

# Wait for services to be healthy
print_message "Waiting for infrastructure services to be healthy..."
sleep 10

# 3. Start API service 
print_message "Starting API service..."
docker compose -f "${DOCKER_DIR}/docker-compose.yml" -f "${DOCKER_DIR}/docker-compose.override.yml" up -d api

# 4. Run migrations
print_message "Running database migrations..."
docker compose -f "${DOCKER_DIR}/docker-compose.yml" -f "${DOCKER_DIR}/docker-compose.override.yml" exec -T api python manage.py migrate --noinput

# 5. Collect static files
print_message "Collecting static files..."
docker compose -f "${DOCKER_DIR}/docker-compose.yml" -f "${DOCKER_DIR}/docker-compose.override.yml" exec -T api python manage.py collectstatic --noinput

# 6. Start worker and scheduler (only after migrations are complete)
print_message "Starting Celery worker and scheduler..."
docker compose -f "${DOCKER_DIR}/docker-compose.yml" -f "${DOCKER_DIR}/docker-compose.override.yml" up -d worker scheduler

# 7. Start remaining services (app, nginx, monitoring)
print_message "Starting remaining services..."
docker compose -f "${DOCKER_DIR}/docker-compose.yml" -f "${DOCKER_DIR}/docker-compose.override.yml" up -d --remove-orphans

print_success "Deployment completed successfully!"
print_message "Your LaunchKit application is now running."

# Display information based on environment
if [ "$DJANGO_ENV" == "development" ]; then
  print_message "Access your application at: http://localhost:8000"
  print_message "API is available at: http://localhost:8000/api"
  print_message "Django admin interface: http://localhost:8000/admin/"
else
  # For staging/production
  print_message "Access your application at: https://www.${DOMAIN_NAME}"
  print_message "API is available at: https://api.${DOMAIN_NAME}"
  print_message "Monitoring is available at: https://monitor.${DOMAIN_NAME}"
fi
