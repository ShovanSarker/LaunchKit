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
  echo -e "${BLUE}[LaunchKit]${NC} $1"
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

# Parse command line arguments
ENVIRONMENT=""
FORCE=false
NON_INTERACTIVE=false

show_help() {
  echo "Usage: ./scripts/setup.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -e, --environment ENV    Set environment (development, staging, production)"
  echo "  -f, --force              Force overwrite of existing files"
  echo "  -n, --non-interactive    Run in non-interactive mode"
  echo "  -h, --help               Show this help message"
  echo ""
  exit 0
}

# Parse arguments
while (( "$#" )); do
  case "$1" in
    -e|--environment)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        ENVIRONMENT=$2
        shift 2
      else
        print_error "Error: Argument for $1 is missing"
        exit 1
      fi
      ;;
    -f|--force)
      FORCE=true
      shift
      ;;
    -n|--non-interactive)
      NON_INTERACTIVE=true
      shift
      ;;
    -h|--help)
      show_help
      ;;
    *)
      print_error "Unknown option: $1"
      show_help
      ;;
  esac
done

# Check dependencies
check_dependencies() {
  print_message "Checking dependencies..."
  
  # Check if Docker is installed
  if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker and try again."
    exit 1
  fi
  
  # Check if Docker Compose is installed
  if ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
  fi
  
  print_success "All dependencies are installed."
}

# Generate random string for secrets
generate_random_string() {
  length=${1:-50}
  # Exclude problematic characters like <, >, |, etc. that can cause issues with sed
  LC_ALL=C tr -dc 'a-zA-Z0-9!@#$%^&*()_+{}=' < /dev/urandom | head -c${length}
}

# Check if files already exist
check_existing_files() {
  if [ "$FORCE" = "false" ]; then
    if [ -f "${PROJECT_ROOT}/.env" ]; then
      print_warning "Environment file already exists. Use --force to overwrite."
      exit 1
    fi
  fi
}

# Get environment type
get_environment_type() {
  if [ -z "$ENVIRONMENT" ]; then
    if [ "$NON_INTERACTIVE" = "true" ]; then
      ENVIRONMENT="development"
    else
      print_message "Choose environment type:"
      echo "1) Development (local)"
      echo "2) Staging"
      echo "3) Production"
      read -p "Enter your choice [1-3]: " env_choice
      
      case $env_choice in
        1)
          ENVIRONMENT="development"
          ;;
        2)
          ENVIRONMENT="staging"
          ;;
        3)
          ENVIRONMENT="production"
          ;;
        *)
          print_error "Invalid choice. Defaulting to development."
          ENVIRONMENT="development"
          ;;
      esac
    fi
  fi
  
  print_message "Setting up environment: ${ENVIRONMENT}"
}

# Get project information
get_project_info() {
  if [ "$NON_INTERACTIVE" = "true" ]; then
    PROJECT_NAME=${PROJECT_NAME:-"LaunchKit"}
    PROJECT_SLUG=${PROJECT_SLUG:-"launchkit"}
    DOMAIN_NAME=${DOMAIN_NAME:-"example.com"}
  else
    read -p "Enter project name (e.g., MyProject): " PROJECT_NAME
    PROJECT_NAME=${PROJECT_NAME:-"LaunchKit"}
    
    read -p "Enter project slug (lowercase, no spaces): " PROJECT_SLUG
    PROJECT_SLUG=${PROJECT_SLUG:-"launchkit"}
    
    if [ "$ENVIRONMENT" != "development" ]; then
      read -p "Enter domain name (e.g., example.com): " DOMAIN_NAME
      DOMAIN_NAME=${DOMAIN_NAME:-"example.com"}
      
      read -p "Enter email for Let's Encrypt: " LE_EMAIL
      LE_EMAIL=${LE_EMAIL:-"admin@${DOMAIN_NAME}"}
    else
      DOMAIN_NAME="localhost"
      LE_EMAIL="admin@example.com"
    fi
  fi
}

# Set environment-specific variables
set_environment_variables() {
  # Common variables
  SECRET_KEY=$(generate_random_string 50)
  POSTGRES_PASSWORD=$(generate_random_string 16)
  RABBITMQ_PASSWORD=$(generate_random_string 16)
  
  # Database settings
  POSTGRES_DB="${PROJECT_SLUG}"
  POSTGRES_USER="${PROJECT_SLUG}"
  
  # Redis and RabbitMQ URLs
  REDIS_URL="redis://redis:6379/0"
  CELERY_BROKER_URL="amqp://${PROJECT_SLUG}:${RABBITMQ_PASSWORD}@rabbitmq:5672/${PROJECT_SLUG}"
  
  # Environment-specific variables
  case "$ENVIRONMENT" in
    development)
      # Development settings already covered above
      ;;
    staging)
      # Add any staging-specific variables
      AWS_S3_BUCKET="${PROJECT_SLUG}-staging"
      AWS_S3_BUCKET_STAGING="${PROJECT_SLUG}-staging"
      AWS_S3_CUSTOM_DOMAIN_STAGING="staging-media.${DOMAIN_NAME}"
      ;;
    production)
      # Add any production-specific variables
      AWS_S3_BUCKET="${PROJECT_SLUG}-production"
      AWS_S3_REGION="us-east-1"
      AWS_S3_CUSTOM_DOMAIN="media.${DOMAIN_NAME}"
      ;;
  esac
}

# Apply template
apply_template() {
  template_file="$1"
  output_file="$2"
  
  if [ ! -f "$template_file" ]; then
    print_error "Template file not found: $template_file"
    exit 1
  fi
  
  # Create output directory if it doesn't exist
  output_dir=$(dirname "$output_file")
  mkdir -p "$output_dir"
  
  # Copy template to output
  cp "$template_file" "$output_file"
  
  # Replace variables in the output file
  # Project info
  sed -i.bak "s|%%PROJECT_NAME%%|${PROJECT_NAME}|g" "$output_file"
  sed -i.bak "s|%%PROJECT_SLUG%%|${PROJECT_SLUG}|g" "$output_file"
  sed -i.bak "s|%%DOMAIN_NAME%%|${DOMAIN_NAME}|g" "$output_file"
  sed -i.bak "s|%%LE_EMAIL%%|${LE_EMAIL}|g" "$output_file"
  
  # Credentials
  sed -i.bak "s|%%SECRET_KEY%%|${SECRET_KEY}|g" "$output_file"
  sed -i.bak "s|%%POSTGRES_PASSWORD%%|${POSTGRES_PASSWORD}|g" "$output_file"
  sed -i.bak "s|%%RABBITMQ_PASSWORD%%|${RABBITMQ_PASSWORD}|g" "$output_file"
  sed -i.bak "s|%%POSTGRES_DB%%|${POSTGRES_DB}|g" "$output_file"
  sed -i.bak "s|%%POSTGRES_USER%%|${POSTGRES_USER}|g" "$output_file"
  
  # URLs and connections
  sed -i.bak "s|%%REDIS_URL%%|${REDIS_URL}|g" "$output_file"
  sed -i.bak "s|%%CELERY_BROKER_URL%%|${CELERY_BROKER_URL}|g" "$output_file"
  
  # Optional services (if they exist)
  if [ -n "${AWS_ACCESS_KEY_ID+x}" ]; then
    sed -i.bak "s|%%AWS_ACCESS_KEY_ID%%|${AWS_ACCESS_KEY_ID}|g" "$output_file"
  fi
  if [ -n "${AWS_SECRET_ACCESS_KEY+x}" ]; then
    sed -i.bak "s|%%AWS_SECRET_ACCESS_KEY%%|${AWS_SECRET_ACCESS_KEY}|g" "$output_file"
  fi
  if [ -n "${AWS_S3_BUCKET+x}" ]; then
    sed -i.bak "s|%%AWS_S3_BUCKET%%|${AWS_S3_BUCKET}|g" "$output_file"
  fi
  if [ -n "${AWS_S3_BUCKET_STAGING+x}" ]; then
    sed -i.bak "s|%%AWS_S3_BUCKET_STAGING%%|${AWS_S3_BUCKET_STAGING}|g" "$output_file"
  fi
  if [ -n "${AWS_S3_REGION+x}" ]; then
    sed -i.bak "s|%%AWS_S3_REGION%%|${AWS_S3_REGION}|g" "$output_file"
  fi
  if [ -n "${AWS_S3_CUSTOM_DOMAIN+x}" ]; then
    sed -i.bak "s|%%AWS_S3_CUSTOM_DOMAIN%%|${AWS_S3_CUSTOM_DOMAIN}|g" "$output_file"
  fi
  if [ -n "${AWS_S3_CUSTOM_DOMAIN_STAGING+x}" ]; then
    sed -i.bak "s|%%AWS_S3_CUSTOM_DOMAIN_STAGING%%|${AWS_S3_CUSTOM_DOMAIN_STAGING}|g" "$output_file"
  fi
  if [ -n "${SENDGRID_API_KEY+x}" ]; then
    sed -i.bak "s|%%SENDGRID_API_KEY%%|${SENDGRID_API_KEY}|g" "$output_file"
  fi
  if [ -n "${SENTRY_DSN+x}" ]; then
    sed -i.bak "s|%%SENTRY_DSN%%|${SENTRY_DSN}|g" "$output_file"
  fi
  if [ -n "${GOOGLE_ANALYTICS+x}" ]; then
    sed -i.bak "s|%%GOOGLE_ANALYTICS%%|${GOOGLE_ANALYTICS}|g" "$output_file"
  fi
  
  # Remove backup file
  rm -f "${output_file}.bak"
  
  print_success "Created: $output_file"
}

# Apply environment configuration
apply_environment_config() {
  print_message "Applying ${ENVIRONMENT} environment configuration..."
  
  # Apply API environment template
  api_env_template="${TEMPLATES_DIR}/env/${ENVIRONMENT}/api.env.template"
  apply_template "$api_env_template" "${PROJECT_ROOT}/api/.env"
  
  # Apply Next.js app environment template
  app_env_template="${TEMPLATES_DIR}/env/${ENVIRONMENT}/app.env.template"
  apply_template "$app_env_template" "${PROJECT_ROOT}/app/.env.local"
  
  # Create main .env for Docker Compose
  # This is just a subset of variables needed by Docker Compose
  cat > "${PROJECT_ROOT}/.env" << EOF
# Project settings
PROJECT_NAME=${PROJECT_NAME}
PROJECT_SLUG=${PROJECT_SLUG}
DOMAIN_NAME=${DOMAIN_NAME}

# Database settings
POSTGRES_DB=${POSTGRES_DB}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# RabbitMQ
RABBITMQ_DEFAULT_USER=${PROJECT_SLUG}
RABBITMQ_DEFAULT_PASS=${RABBITMQ_PASSWORD}
RABBITMQ_DEFAULT_VHOST=${PROJECT_SLUG}

# Environment
ENVIRONMENT=${ENVIRONMENT}
EOF
  
  print_success "Created: ${PROJECT_ROOT}/.env"
}

# Start services
start_services() {
  if [ "$NON_INTERACTIVE" = "true" ]; then
    return
  fi
  
  print_message "Do you want to start the services now? (y/n)"
  read -p "> " start_choice
  
  if [[ "$start_choice" =~ ^[Yy]$ ]]; then
    print_message "Starting services..."
    cd "$PROJECT_ROOT"
    docker compose up -d
    
    print_success "Services started successfully!"
    
    print_message "Running migrations..."
    docker compose exec api python manage.py migrate
    
    print_success "Migrations applied successfully!"
    
    print_message "Creating superuser..."
    docker compose exec api python manage.py createsuperuser --noinput
  fi
}

# Main script
main() {
  print_message "LaunchKit Environment Setup"
  print_message "==========================="
  echo
  
  check_dependencies
  check_existing_files
  get_environment_type
  get_project_info
  set_environment_variables
  apply_environment_config
  start_services
  
  echo
  print_success "LaunchKit environment setup complete!"
  echo
  
  if [ "$ENVIRONMENT" = "development" ]; then
    print_message "For development environment, your services are available at:"
    echo "  - Frontend: http://localhost:3000"
    echo "  - API: http://localhost:8000"
    echo "  - API Admin: http://localhost:8000/admin"
  else
    print_message "For ${ENVIRONMENT} environment, your services will be available at:"
    echo "  - Frontend: https://www.${DOMAIN_NAME}"
    echo "  - API: https://api.${DOMAIN_NAME}"
    echo "  - API Admin: https://api.${DOMAIN_NAME}/admin"
  fi
  
  echo
  print_message "Next steps:"
  echo "  1. Review the generated environment files"
  echo "  2. Run 'docker compose up -d' to start the services"
  echo "  3. Run 'docker compose exec api python manage.py migrate' to apply migrations"
  echo "  4. Run 'docker compose exec api python manage.py createsuperuser' to create an admin user"
  echo
}

# Run the main function
main 