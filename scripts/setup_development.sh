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
  echo -e "${BLUE}[Setup]${NC} $1"
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

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATES_DIR="${PROJECT_ROOT}/templates"

# Generate random string for secrets
generate_random_string() {
  length=${1:-50}
  LC_ALL=C tr -dc 'a-zA-Z0-9!@%^&*_+=' < /dev/urandom | head -c${length}
}

# Check if a file exists and ask before overwriting
check_file_exists() {
  local file=$1
  if [ -f "$file" ]; then
    print_warning "File already exists: $file"
    print_warning "This script will not overwrite existing environment files."
    return 1
  fi
  return 0
}

# Create file if it doesn't exist or append content if it does
append_or_create_file() {
  local file=$1
  local content=$2
  local should_append=${3:-false}
  
  # Create directory if it doesn't exist
  mkdir -p "$(dirname "$file")"
  
  if [ "$should_append" = true ] && [ -f "$file" ]; then
    # Append content to file
    echo "$content" >> "$file"
    print_success "Updated: $file"
  else
    # Create new file with content
    echo "$content" > "$file"
    print_success "Created: $file"
  fi
}

# Function to get project info
get_project_info() {
  print_message "Enter project information:"
  
  read -p "Enter project name (e.g., MyProject): " PROJECT_NAME
  PROJECT_NAME=${PROJECT_NAME:-"LaunchKit"}
  
  # Convert project name to lowercase for slug
  suggested_slug=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
  read -p "Enter project slug (lowercase, no spaces) [$suggested_slug]: " PROJECT_SLUG
  PROJECT_SLUG=${PROJECT_SLUG:-$suggested_slug}
  
  read -p "Enter project description: " PROJECT_DESCRIPTION
  PROJECT_DESCRIPTION=${PROJECT_DESCRIPTION:-"A full-stack boilerplate for modern web applications"}
  
  # Export variables for Docker and other processes
  export PROJECT_NAME
  export PROJECT_SLUG
  
  # Create or update root .env file with project settings
  cat > "${PROJECT_ROOT}/.env" << EOL
# Project Settings
PROJECT_NAME=${PROJECT_NAME}
PROJECT_SLUG=${PROJECT_SLUG}
EOL
  
  print_message "Project name: ${PROJECT_NAME}"
  print_message "Project slug: ${PROJECT_SLUG}"
  print_message "Project description: ${PROJECT_DESCRIPTION}"
}

# Function to create development environment templates
create_development_templates() {
  print_message "Creating development environment templates..."
  
  # Create templates directory
  mkdir -p "${TEMPLATES_DIR}/env/development"
  
  # Create API environment template
  cat > "${TEMPLATES_DIR}/env/development/api.env.template" << 'EOL'
# =============================================================================
# LaunchKit - API Environment Configuration (Development)
# =============================================================================
# Copy this file to api/.env and update the values below

# =============================================================================
# PROJECT SETTINGS
# =============================================================================
# TODO: Update these with your project information
PROJECT_NAME=LaunchKit
PROJECT_SLUG=launchkit

# =============================================================================
# DJANGO SETTINGS
# =============================================================================
# TODO: Set to 'development' for development deployment
DJANGO_ENV=development

# TODO: Set to True for development
DEBUG=True

# TODO: Generate a secure secret key (use: openssl rand -base64 32)
DJANGO_SECRET_KEY=your-secret-key-here

# TODO: Add your development hosts (comma-separated)
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0

# TODO: Add your frontend URLs (comma-separated)
CSRF_TRUSTED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# =============================================================================
# DATABASE SETTINGS
# =============================================================================
# TODO: Update with your database credentials
POSTGRES_DB=launchkit
POSTGRES_USER=launchkit
POSTGRES_PASSWORD=your-db-password-here
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# =============================================================================
# REDIS SETTINGS
# =============================================================================
# TODO: Update Redis URL if using external Redis
REDIS_URL=redis://redis:6379/0

# =============================================================================
# RABBITMQ SETTINGS
# =============================================================================
# TODO: Update with your RabbitMQ credentials
CELERY_BROKER_URL=amqp://launchkit:password@rabbitmq:5672/launchkit
CELERY_RESULT_BACKEND=redis://redis:6379/0

# =============================================================================
# EMAIL SETTINGS (DEVELOPMENT)
# =============================================================================
# TODO: Configure your email backend for development
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend

# For testing with real email in development:
# EMAIL_BACKEND=sendgrid_backend.SendgridBackend
# SENDGRID_API_KEY=your-sendgrid-api-key-here
# SENDGRID_FROM_EMAIL=your-email@your-domain.com

# =============================================================================
# FRONTEND URL
# =============================================================================
# TODO: Update with your frontend URL
FRONTEND_URL=http://localhost:3000

# =============================================================================
# LOGGING SETTINGS
# =============================================================================
LOG_LEVEL=DEBUG
LOG_FILE=/var/log/launchkit/api.log

# =============================================================================
# SECURITY SETTINGS
# =============================================================================
# TODO: Configure security settings for development
SECURE_SSL_REDIRECT=False
SECURE_HSTS_SECONDS=0
SECURE_HSTS_INCLUDE_SUBDOMAINS=False
SECURE_HSTS_PRELOAD=False
SECURE_CONTENT_TYPE_NOSNIFF=False
SECURE_BROWSER_XSS_FILTER=False
X_FRAME_OPTIONS=SAMEORIGIN

# =============================================================================
# CORS SETTINGS
# =============================================================================
# TODO: Add your frontend domain
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
CORS_ALLOW_CREDENTIALS=True

# =============================================================================
# JWT SETTINGS
# =============================================================================
# TODO: Generate secure JWT keys
JWT_SECRET_KEY=your-jwt-secret-key-here
JWT_ACCESS_TOKEN_LIFETIME=5
JWT_REFRESH_TOKEN_LIFETIME=1

# =============================================================================
# MONITORING SETTINGS
# =============================================================================
# TODO: Configure monitoring endpoints
PROMETHEUS_METRICS_EXPORT_PORT=8001
PROMETHEUS_METRICS_EXPORT_ADDRESS=0.0.0.0
EOL

  # Create Frontend environment template
  cat > "${TEMPLATES_DIR}/env/development/app.env.template" << 'EOL'
# =============================================================================
# LaunchKit - Frontend Environment Configuration (Development)
# =============================================================================
# Copy this file to app/.env.local and update the values below

# =============================================================================
# PROJECT INFORMATION
# =============================================================================
# TODO: Update with your project information
NEXT_PUBLIC_PROJECT_NAME=LaunchKit
NEXT_PUBLIC_PROJECT_SLUG=launchkit

# =============================================================================
# API SETTINGS
# =============================================================================
# TODO: Update with your API URL
NEXT_PUBLIC_API_URL=http://localhost:8000

# =============================================================================
# AUTHENTICATION SETTINGS
# =============================================================================
# TODO: Update with your domain
NEXTAUTH_URL=http://localhost:3000

# TODO: Generate a secure secret (use: openssl rand -base64 32)
NEXTAUTH_SECRET=your-nextauth-secret-here

# =============================================================================
# FEATURE FLAGS
# =============================================================================
# TODO: Configure feature flags based on your needs
NEXT_PUBLIC_FEATURE_REGISTRATION_ENABLED=true
NEXT_PUBLIC_FEATURE_SOCIAL_LOGIN_ENABLED=false
NEXT_PUBLIC_FEATURE_EMAIL_VERIFICATION_ENABLED=true
NEXT_PUBLIC_FEATURE_PASSWORD_RESET_ENABLED=true

# =============================================================================
# ANALYTICS SETTINGS
# =============================================================================
# TODO: Add your analytics configuration
NEXT_PUBLIC_GOOGLE_ANALYTICS_ID=
NEXT_PUBLIC_MIXPANEL_TOKEN=

# =============================================================================
# MONITORING SETTINGS
# =============================================================================
# TODO: Configure monitoring endpoints
NEXT_PUBLIC_MONITORING_URL=http://localhost:3000
NEXT_PUBLIC_HEALTH_CHECK_URL=http://localhost:8000/api/health/

# =============================================================================
# DEVELOPMENT SETTINGS
# =============================================================================
# TODO: Set to true in development
NODE_ENV=development
NEXT_PUBLIC_DEBUG_MODE=true
EOL

  # Create Docker environment template
  cat > "${TEMPLATES_DIR}/env/development/docker.env.template" << 'EOL'
# =============================================================================
# LaunchKit - Docker Environment Configuration (Development)
# =============================================================================
# Copy this file to docker/.env and update the values below

# =============================================================================
# PROJECT SETTINGS
# =============================================================================
# TODO: Update with your project information
PROJECT_NAME=LaunchKit
PROJECT_SLUG=launchkit

# =============================================================================
# DOMAIN SETTINGS
# =============================================================================
# TODO: Update with your domain
DOMAIN=localhost
EMAIL=admin@localhost

# =============================================================================
# DATABASE SETTINGS
# =============================================================================
# TODO: Update with your database credentials
POSTGRES_DB=launchkit
POSTGRES_USER=launchkit
POSTGRES_PASSWORD=your-db-password-here

# =============================================================================
# RABBITMQ SETTINGS
# =============================================================================
# TODO: Update with your RabbitMQ credentials
RABBITMQ_DEFAULT_USER=launchkit
RABBITMQ_DEFAULT_PASS=your-rabbitmq-password-here
RABBITMQ_DEFAULT_VHOST=launchkit

# =============================================================================
# MONITORING SETTINGS
# =============================================================================
# TODO: Update with your monitoring credentials
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=your-grafana-password-here

# =============================================================================
# SSL SETTINGS
# =============================================================================
# TODO: Configure SSL settings
SSL_ENABLED=false
SSL_EMAIL=admin@localhost

# =============================================================================
# BACKUP SETTINGS
# =============================================================================
# TODO: Configure backup settings
BACKUP_ENABLED=false
BACKUP_RETENTION_DAYS=7
BACKUP_SCHEDULE=0 2 * * *

# =============================================================================
# SECURITY SETTINGS
# =============================================================================
# TODO: Configure security settings
FAIL2BAN_ENABLED=false
UFW_ENABLED=false
SECURITY_HEADERS_ENABLED=false

# =============================================================================
# PERFORMANCE SETTINGS
# =============================================================================
# TODO: Configure performance settings
NGINX_WORKER_PROCESSES=auto
NGINX_WORKER_CONNECTIONS=1024
NGINX_KEEPALIVE_TIMEOUT=65
NGINX_CLIENT_MAX_BODY_SIZE=10M
EOL

  print_success "Development environment templates created"
}

# Function to create run scripts directory
create_run_scripts() {
  print_message "Creating run scripts directory structure..."
  
  # Create run directories
  mkdir -p "${PROJECT_ROOT}/run/development"
  mkdir -p "${PROJECT_ROOT}/run/production"
  
  # Make existing scripts executable
  chmod +x "${PROJECT_ROOT}/run/development"/*.sh 2>/dev/null || true
  chmod +x "${PROJECT_ROOT}/run/production"/*.sh 2>/dev/null || true
  
  print_success "Run scripts directory structure created"
}

# Function to display next steps
display_next_steps() {
  print_success "Development setup completed!"
  echo ""
  echo "Next steps:"
  echo "1. Configure environment files:"
  echo "   cp templates/env/development/api.env.template api/.env"
  echo "   cp templates/env/development/app.env.template app/.env.local"
  echo "   cp templates/env/development/docker.env.template docker/.env"
  echo ""
  echo "2. Edit the environment files with your values"
  echo ""
  echo "3. Start development services:"
  echo "   ./run/development/run_dev_all.sh"
  echo ""
  echo "4. Start Next.js development server:"
  echo "   cd app && npm run dev"
  echo ""
  echo "5. Access your application:"
  echo "   Frontend: http://localhost:3000"
  echo "   Backend API: http://localhost:8000"
  echo "   API Docs: http://localhost:8000/api/docs/"
  echo ""
  echo "6. View the setup guide for detailed instructions:"
  echo "   cat run/SETUP_GUIDE.md"
  echo ""
}

# Main function
main() {
  print_message "Starting LaunchKit development setup..."
  
  # Get project information
  get_project_info
  
  # Create development templates
  create_development_templates
  
  # Create run scripts
  create_run_scripts
  
  # Display next steps
  display_next_steps
}

# Run main function
main "$@" 