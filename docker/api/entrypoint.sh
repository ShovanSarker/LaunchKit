#!/bin/bash

set -e

# Wait for PostgreSQL to be ready
until PGPASSWORD=$POSTGRES_PASSWORD psql -h "$POSTGRES_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c '\q'; do
  >&2 echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

>&2 echo "PostgreSQL is up - executing command"

# Apply database migrations
python manage.py migrate

# Collect static files
python manage.py collectstatic --noinput

# Create cache tables
python manage.py createcachetable

exec "$@" 