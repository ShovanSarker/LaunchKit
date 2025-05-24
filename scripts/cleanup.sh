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

# Confirm with user
echo -e "${RED}WARNING: This will remove all docker containers, volumes, and environment files.${NC}"
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
if [ -f "${PROJECT_ROOT}/docker/docker-compose.yml" ]; then
    cd "${PROJECT_ROOT}/docker" && docker compose down -v --remove-orphans
    print_success "Docker containers and volumes removed."
else
    print_warning "docker-compose.yml not found, skipping Docker cleanup."
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

print_message "Cleanup complete! Your project has been reset to its initial state."
print_message "To set up the development environment again, run: ./scripts/setup_development.sh" 