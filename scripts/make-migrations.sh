#!/bin/bash
set -e

# Color codes for terminal output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}[LaunchKit]${NC} Making migrations for all apps..."

# Make migrations for all apps
docker exec docker-api-1 python manage.py makemigrations --noinput

# Specifically make migrations for accounts app
echo -e "${BLUE}[LaunchKit]${NC} Making migrations for accounts app..."
docker exec docker-api-1 python manage.py makemigrations accounts --noinput

echo -e "${GREEN}[SUCCESS]${NC} Migrations created."
echo
echo -e "${BLUE}[LaunchKit]${NC} Now run ./scripts/run-migrations.sh to apply the migrations." 