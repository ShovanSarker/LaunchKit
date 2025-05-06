#!/bin/bash
set -e

# Color codes for terminal output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}[LaunchKit]${NC} Modifying Django settings to fix CELERY_RESULT_BACKEND"

# Start the API container in a temporary mode to modify the settings file
docker run --rm -it -v "$(pwd)/api:/app" docker-api /bin/bash -c '
    # Check if the settings file exists
    if [ -f "/app/project/settings/base.py" ]; then
        # Create a backup of the original file
        cp /app/project/settings/base.py /app/project/settings/base.py.bak
        
        # Replace the CELERY_RESULT_BACKEND line with one that has a default value
        sed -i "s/CELERY_RESULT_BACKEND = env(\"CELERY_RESULT_BACKEND\")/CELERY_RESULT_BACKEND = env(\"CELERY_RESULT_BACKEND\", default=env(\"REDIS_URL\"))/g" /app/project/settings/base.py
        
        echo "✓ Settings file updated successfully"
    else
        echo "✗ Settings file not found at /app/project/settings/base.py"
        exit 1
    fi
'

echo -e "${GREEN}[SUCCESS]${NC} Django settings updated"
echo -e "${BLUE}[LaunchKit]${NC} You can now run ./scripts/run-dev.sh to start the development environment" 