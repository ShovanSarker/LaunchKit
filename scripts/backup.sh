#!/bin/bash
set -e

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${PROJECT_ROOT}/backups"

# Color codes for terminal output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print styled messages
print_message() {
  echo -e "${BLUE}[LaunchKit Backup]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Load environment variables
if [ -f "${PROJECT_ROOT}/.env" ]; then
  source "${PROJECT_ROOT}/.env"
else
  print_error "Environment file not found. Please run ./scripts/init.sh first."
  exit 1
fi

# Check for live environment
if [ "${DJANGO_ENV}" == "development" ]; then
  print_warning "You are creating a backup in development mode."
  print_warning "Backups are typically for production/staging environments."
  read -p "Continue anyway? (y/n): " continue_anyway
  if [ "$continue_anyway" != "y" ]; then
    print_message "Backup aborted."
    exit 0
  fi
fi

# Create backup directory
mkdir -p "${BACKUP_DIR}"
print_message "Created backup directory: ${BACKUP_DIR}"

# Backup PostgreSQL database
print_message "Backing up PostgreSQL database..."
docker compose -f "${PROJECT_ROOT}/docker/docker-compose.yml" \
  -f "${PROJECT_ROOT}/docker/docker-compose.override.yml" \
  exec -T postgres pg_dump -U "${POSTGRES_USER:-launchkit}" "${POSTGRES_DB:-launchkit}" | \
  gzip > "${BACKUP_DIR}/${POSTGRES_DB:-launchkit}_${TIMESTAMP}.sql.gz"

print_success "Database backup created: ${BACKUP_DIR}/${POSTGRES_DB:-launchkit}_${TIMESTAMP}.sql.gz"

# Backup media files
if [ "${AWS_S3_BUCKET}" != "" ] && [ "${AWS_ACCESS_KEY_ID}" != "" ] && [ "${AWS_SECRET_ACCESS_KEY}" != "" ]; then
  print_message "Backing up media files to S3..."
  
  # Check if the AWS CLI is installed in the API container
  if docker compose -f "${PROJECT_ROOT}/docker/docker-compose.yml" \
      -f "${PROJECT_ROOT}/docker/docker-compose.override.yml" \
      exec -T api which aws >/dev/null 2>&1; then
    
    # Use the AWS CLI in the API container
    docker compose -f "${PROJECT_ROOT}/docker/docker-compose.yml" \
      -f "${PROJECT_ROOT}/docker/docker-compose.override.yml" \
      exec -T api aws s3 sync /app/media "s3://${AWS_S3_BUCKET}/backups/media_${TIMESTAMP}/"
    
    print_success "Media files backed up to S3: s3://${AWS_S3_BUCKET}/backups/media_${TIMESTAMP}/"
  else
    print_warning "AWS CLI not found in API container. Skipping media backup."
    print_warning "Please ensure the AWS CLI is installed in your API container."
  fi
else
  print_warning "AWS credentials not found. Skipping media backup to S3."
  print_message "To enable S3 backups, make sure AWS_S3_BUCKET, AWS_ACCESS_KEY_ID, and AWS_SECRET_ACCESS_KEY are set in your .env file."
  
  # Create a local media backup instead
  print_message "Creating local media backup instead..."
  MEDIA_BACKUP_DIR="${BACKUP_DIR}/media_${TIMESTAMP}"
  mkdir -p "${MEDIA_BACKUP_DIR}"
  
  # Copy media files from the Docker volume to the backup directory
  docker compose -f "${PROJECT_ROOT}/docker/docker-compose.yml" \
    -f "${PROJECT_ROOT}/docker/docker-compose.override.yml" \
    cp api:/app/media/. "${MEDIA_BACKUP_DIR}/"
  
  print_success "Media files backed up locally: ${MEDIA_BACKUP_DIR}"
fi

print_success "Backup completed: ${TIMESTAMP}"
print_message "Backup files are stored in: ${BACKUP_DIR}"

# Cleanup old backups (keep only the last 7)
if [ "$(ls -1 "${BACKUP_DIR}"/*.sql.gz 2>/dev/null | wc -l)" -gt 7 ]; then
  print_message "Cleaning up old backups (keeping the 7 most recent)..."
  ls -t "${BACKUP_DIR}"/*.sql.gz | tail -n +8 | xargs rm -f
  print_success "Old backups cleaned up."
fi 