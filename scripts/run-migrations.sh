#!/bin/bash
set -e

# Color codes for terminal output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}[LaunchKit]${NC} Running database migrations..."

# Run migrations for all apps
docker exec docker-api-1 python manage.py migrate --noinput

# Specifically run migrations for accounts app if it exists
echo -e "${BLUE}[LaunchKit]${NC} Running migrations for accounts app..."
docker exec docker-api-1 python manage.py migrate accounts --noinput || true

echo -e "${GREEN}[SUCCESS]${NC} Database migrations completed."
echo
echo -e "${BLUE}[LaunchKit]${NC} Creating admin user..."

# Create a superuser (non-interactive)
docker exec -e DJANGO_SUPERUSER_USERNAME=admin -e DJANGO_SUPERUSER_PASSWORD=admin -e DJANGO_SUPERUSER_EMAIL=admin@example.com docker-api-1 python manage.py createsuperuser --noinput || true

echo -e "${BLUE}[LaunchKit]${NC} Creating profiles for existing users..."

# Run a Django shell command to fix the profiles
docker exec docker-api-1 python manage.py shell -c "
from django.contrib.auth.models import User
from apps.accounts.models import Profile

# Create profiles for users that don't have one
for user in User.objects.all():
    try:
        # Check if profile exists
        profile = user.profile
        print(f'Profile already exists for user {user.username}')
    except User.profile.RelatedObjectDoesNotExist:
        # Create profile if it doesn't exist
        Profile.objects.create(user=user)
        print(f'Created profile for user {user.username}')
"

echo -e "${GREEN}[SUCCESS]${NC} Admin user created with credentials admin/admin"
echo -e "${BLUE}[LaunchKit]${NC} You can now access the admin interface at http://localhost:8000/admin/" 