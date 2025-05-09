#!/bin/bash
set -e

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_DIR="${PROJECT_ROOT}/docker"

# Color codes for terminal output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Print message
echo -e "${BLUE}[LaunchKit]${NC} Starting development environment..."

# Start development services
docker compose -f "${DOCKER_DIR}/docker-compose.yml" -f "${DOCKER_DIR}/docker-compose.override.yml" up -d

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
echo "  docker compose -f \"${DOCKER_DIR}/docker-compose.yml\" -f \"${DOCKER_DIR}/docker-compose.override.yml\" down"
