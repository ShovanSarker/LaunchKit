#!/bin/bash
set -e

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_DIR="${PROJECT_ROOT}/docker"

# Color codes for terminal output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Define essential services
ESSENTIAL_SERVICES="postgres redis rabbitmq api worker scheduler"

# Check if we need to process commands
if [ "$1" = "down" ]; then
  echo -e "${BLUE}[LaunchKit]${NC} Stopping all services..."
  docker compose -f "${DOCKER_DIR}/docker-compose.dev-services.yml" down
  echo -e "${GREEN}[SUCCESS]${NC} All services stopped."
  exit 0
elif [ "$1" = "ps" ]; then
  echo -e "${BLUE}[LaunchKit]${NC} Checking running services..."
  docker compose -f "${DOCKER_DIR}/docker-compose.dev-services.yml" ps
  exit 0
elif [ "$1" = "logs" ]; then
  if [ "$2" != "" ]; then
    echo -e "${BLUE}[LaunchKit]${NC} Showing logs for $2..."
    docker compose -f "${DOCKER_DIR}/docker-compose.dev-services.yml" logs -f "$2"
  else
    echo -e "${BLUE}[LaunchKit]${NC} Showing logs for essential services..."
    docker compose -f "${DOCKER_DIR}/docker-compose.dev-services.yml" logs -f $ESSENTIAL_SERVICES
  fi
  exit 0
fi

# Print message
echo -e "${BLUE}[LaunchKit]${NC} Starting development environment..."
echo -e "${BLUE}[LaunchKit]${NC} Will start only essential services: postgres redis rabbitmq api worker scheduler"
echo -e "${BLUE}[LaunchKit]${NC} (Nginx, monitoring tools, and the Next.js app will NOT be started)"

# Load environment variables
if [ -f "${PROJECT_ROOT}/.env" ]; then
  source "${PROJECT_ROOT}/.env"
fi

# Create a temporary docker-compose file for development that does not try to build locally
cat > "${DOCKER_DIR}/docker-compose.dev-services.yml" << EOF
services:
  postgres:
    image: postgres:15
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=${POSTGRES_DB:-launchkit}
      - POSTGRES_USER=${POSTGRES_USER:-launchkit}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-password}
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - launchkit_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${POSTGRES_USER:-launchkit}"]
      interval: 5s
      timeout: 5s
      retries: 5
  
  redis:
    image: redis:6
    ports:
      - "6379:6379"
    networks:
      - launchkit_network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5
  
  rabbitmq:
    image: rabbitmq:3-management
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      - RABBITMQ_DEFAULT_USER=${POSTGRES_USER:-launchkit}
      - RABBITMQ_DEFAULT_PASS=${RABBITMQ_PASSWORD:-password}
    networks:
      - launchkit_network
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "check_port_connectivity"]
      interval: 30s
      timeout: 10s
      retries: 5
  
  api:
    image: python:3.10
    volumes:
      - ../api:/app
      - media:/app/media
      - static:/app/static
    env_file:
      - ../.env
    environment:
      - DJANGO_ENV=development
      - DEBUG=True
      - POSTGRES_HOST=postgres
      - POSTGRES_DB=${POSTGRES_DB:-launchkit}
      - POSTGRES_USER=${POSTGRES_USER:-launchkit}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-password}
      - POSTGRES_PORT=5432
      - REDIS_URL=redis://redis:6379/0
      - CELERY_BROKER_URL=amqp://${POSTGRES_USER:-launchkit}:${RABBITMQ_PASSWORD:-password}@rabbitmq:5672//
      - CELERY_RESULT_BACKEND=redis://redis:6379/0
    ports:
      - "8000:8000"
    working_dir: /app
    command: ["sh", "-c", "pip install -r requirements/dev.txt && python manage.py runserver 0.0.0.0:8000"]
    networks:
      - launchkit_network
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      rabbitmq:
        condition: service_healthy
  
  worker:
    image: python:3.10
    volumes:
      - ../api:/app
      - media:/app/media
    env_file:
      - ../.env
    environment:
      - DJANGO_ENV=development
      - DEBUG=True
      - POSTGRES_HOST=postgres
      - POSTGRES_DB=${POSTGRES_DB:-launchkit}
      - POSTGRES_USER=${POSTGRES_USER:-launchkit}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-password}
      - POSTGRES_PORT=5432
      - REDIS_URL=redis://redis:6379/0
      - CELERY_BROKER_URL=amqp://${POSTGRES_USER:-launchkit}:${RABBITMQ_PASSWORD:-password}@rabbitmq:5672//
      - CELERY_RESULT_BACKEND=redis://redis:6379/0
    working_dir: /app
    command: ["sh", "-c", "pip install -r requirements/dev.txt && celery -A project worker --loglevel=info"]
    networks:
      - launchkit_network
    depends_on:
      api:
        condition: service_started
  
  scheduler:
    image: python:3.10
    volumes:
      - ../api:/app
    env_file:
      - ../.env
    environment:
      - DJANGO_ENV=development
      - DEBUG=True
      - POSTGRES_HOST=postgres
      - POSTGRES_DB=${POSTGRES_DB:-launchkit}
      - POSTGRES_USER=${POSTGRES_USER:-launchkit}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-password}
      - POSTGRES_PORT=5432
      - REDIS_URL=redis://redis:6379/0
      - CELERY_BROKER_URL=amqp://${POSTGRES_USER:-launchkit}:${RABBITMQ_PASSWORD:-password}@rabbitmq:5672//
      - CELERY_RESULT_BACKEND=redis://redis:6379/0
    working_dir: /app
    command: ["sh", "-c", "pip install -r requirements/dev.txt && celery -A project beat --loglevel=info"]
    networks:
      - launchkit_network
    depends_on:
      api:
        condition: service_started

networks:
  launchkit_network:
    driver: bridge

volumes:
  pgdata:
  media:
  static:
EOF

# Start development services using the temporary file
docker compose -f "${DOCKER_DIR}/docker-compose.dev-services.yml" up -d

# Success message
echo -e "${GREEN}[SUCCESS]${NC} Development environment is running."
echo
echo "Available services:"
echo "- API: http://localhost:8000"
echo "- PostgreSQL: localhost:5432"
echo "- Redis: localhost:6379"
echo "- RabbitMQ: http://localhost:15672 (admin panel)"
echo
echo "To stop all services:"
echo "  ./scripts/run-dev.sh down"
echo
echo "To view logs:"
echo "  ./scripts/run-dev.sh logs [service_name]"
echo
echo "To check running services:"
echo "  ./scripts/run-dev.sh ps"
