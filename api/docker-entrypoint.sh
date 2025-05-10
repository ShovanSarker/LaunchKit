#!/bin/bash

set -e

# Function to check if PostgreSQL is available
postgres_ready() {
    # Check if we can connect to PostgreSQL
    PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT 1" >/dev/null 2>&1
}

# Wait for PostgreSQL to be available
until postgres_ready; do
    echo "PostgreSQL is unavailable - sleeping"
    sleep 1
done

echo "PostgreSQL is up - executing command"

# Apply migrations
if [ "$1" = "python" ] && [ "$2" = "manage.py" ] && [ "$3" = "runserver" ]; then
    echo "Applying migrations..."
    python manage.py migrate --noinput
fi

# Execute the passed command
exec "$@" 