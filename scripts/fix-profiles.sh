#!/bin/bash
set -e

# Color codes for terminal output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}[LaunchKit]${NC} Creating profiles for existing users..."

# Run a Django shell command to fix the profiles
docker exec -it docker-api-1 python manage.py shell -c "
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

echo -e "${GREEN}[SUCCESS]${NC} User profiles have been fixed."
echo -e "${BLUE}[LaunchKit]${NC} You can now log in to the admin interface at http://localhost:8000/admin/" 