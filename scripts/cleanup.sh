#!/bin/bash

set -e

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print styled messages
print_message() {
    echo -e "${BLUE}[Cleanup]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Detect environment
if [ -f "${PROJECT_ROOT}/.env" ]; then
    source "${PROJECT_ROOT}/.env"
    if [ "$ENVIRONMENT" = "production" ]; then
        ENV_TYPE="production"
    else
        ENV_TYPE="development"
    fi
else
    ENV_TYPE="development"
fi

# Confirm with user
echo -e "${RED}WARNING: This will remove all docker containers, volumes, and environment files.${NC}"
echo -e "${RED}Environment: ${ENV_TYPE}${NC}"
echo -e "${RED}This action cannot be undone.${NC}"
read -p "Are you sure you want to proceed? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    print_message "Cleanup cancelled."
    exit 1
fi

# Stop and remove docker containers
print_message "Stopping and removing Docker containers..."
if [ "$ENV_TYPE" = "production" ]; then
    if [ -f "${PROJECT_ROOT}/docker/docker-compose.prod.yml" ]; then
        cd "${PROJECT_ROOT}/docker" && docker compose -f docker-compose.prod.yml down -v --remove-orphans
        print_success "Production Docker containers and volumes removed."
    else
        print_warning "docker-compose.prod.yml not found, skipping Docker cleanup."
    fi
else
    if [ -f "${PROJECT_ROOT}/docker/docker-compose.yml" ]; then
        cd "${PROJECT_ROOT}/docker" && docker compose down -v --remove-orphans
        print_success "Development Docker containers and volumes removed."
    else
        print_warning "docker-compose.yml not found, skipping Docker cleanup."
    fi
fi

# Remove environment files
print_message "Removing environment files..."
files_to_remove=(
    "${PROJECT_ROOT}/api/.env"
    "${PROJECT_ROOT}/app/.env.local"
    "${PROJECT_ROOT}/.env"
    "${PROJECT_ROOT}/docker/.env"
)

for file in "${files_to_remove[@]}"; do
    if [ -f "$file" ]; then
        rm "$file"
        print_success "Removed: $file"
    fi
done

# Remove generated scripts and configurations
print_message "Removing generated scripts and configurations..."
generated_files=(
    "${PROJECT_ROOT}/docker/docker-compose.yml"
    "${PROJECT_ROOT}/docker/docker-compose.prod.yml"
    "${PROJECT_ROOT}/scripts/run_dev.sh"
    "${PROJECT_ROOT}/api/docker-entrypoint.sh"
)

for file in "${generated_files[@]}"; do
    if [ -f "$file" ]; then
        rm "$file"
        print_success "Removed: $file"
    fi
done

# Remove Celery files
print_message "Removing Celery files..."
celery_files=(
    "${PROJECT_ROOT}/celerybeat-schedule"
    "${PROJECT_ROOT}/celerybeat.pid"
    "${PROJECT_ROOT}/celerybeat-schedule.db"
)

for file in "${celery_files[@]}"; do
    if [ -f "$file" ]; then
        rm "$file"
        print_success "Removed: $file"
    fi
done

# Clean Python cache
print_message "Cleaning Python cache..."
find "${PROJECT_ROOT}" -type d -name "__pycache__" -exec rm -r {} + 2>/dev/null || true
find "${PROJECT_ROOT}" -type f -name "*.pyc" -delete
print_success "Python cache cleaned."

# Remove logs directory
if [ -d "${PROJECT_ROOT}/logs" ]; then
    print_message "Removing logs directory..."
    rm -rf "${PROJECT_ROOT}/logs"
    print_success "Logs directory removed."
fi

# Remove SSL certificates in production
if [ "$ENV_TYPE" = "production" ]; then
    print_message "Removing SSL certificates..."
    if [ -d "/etc/letsencrypt/live/${DOMAIN}" ]; then
        certbot delete --cert-name "${DOMAIN}" --non-interactive
        print_success "SSL certificates removed."
    fi
fi

# Remove Nginx configurations
print_message "Removing Nginx configurations..."
nginx_dirs=(
    "${PROJECT_ROOT}/nginx/conf.d"
    "${PROJECT_ROOT}/nginx/ssl"
)

for dir in "${nginx_dirs[@]}"; do
    if [ -d "$dir" ]; then
        rm -rf "$dir"
        print_success "Removed: $dir"
    fi
done

print_message "Cleanup complete! Your project has been reset to its initial state."
if [ "$ENV_TYPE" = "production" ]; then
    print_message "To set up the production environment again, run: ./scripts/deploy_production.sh"
else
    print_message "To set up the development environment again, run: ./scripts/setup_development.sh"
fi 