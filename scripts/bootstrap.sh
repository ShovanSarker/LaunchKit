#!/bin/bash

# =============================================================================
# LaunchKit Bootstrap Script
# =============================================================================
# First-run initializer that prompts for project configuration and generates
# environment files for development or production deployment.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${PROJECT_ROOT}/config"
ENV_DIR="${PROJECT_ROOT}/env"
INFRA_DIR="${PROJECT_ROOT}/infra"

# Function to print messages
print_message() {
    echo -e "${BLUE}[Bootstrap]${NC} $1"
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

# Function to get user input with default value
get_input() {
    local prompt="$1"
    local default="$2"
    local input
    
    read -p "$prompt [$default]: " input
    echo "${input:-$default}"
}

# Function to generate random string
generate_random_string() {
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -hex 32
    else
        # Fallback to /dev/urandom
        cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 64 | head -n 1
    fi
}

# Function to slugify project name
slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-\|-$//g'
}

# Function to validate domain
validate_domain() {
    local domain="$1"
    if [[ "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if file exists and ask before overwriting
check_file_exists() {
    local file="$1"
    if [ -f "$file" ]; then
        print_warning "File already exists: $file"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    return 0
}

# Function to create htpasswd file for production
create_htpasswd() {
    local htpasswd_file="${INFRA_DIR}/auth/htpasswd"
    
    print_message "Creating htpasswd file for Flower authentication..."
    
    # Create auth directory if it doesn't exist
    mkdir -p "${INFRA_DIR}/auth"
    
    # Get username and password for Flower
    local flower_user=$(get_input "Enter username for Flower monitoring" "admin")
    local flower_pass=""
    
    while [ -z "$flower_pass" ]; do
        read -s -p "Enter password for Flower monitoring: " flower_pass
        echo
        if [ -z "$flower_pass" ]; then
            print_error "Password cannot be empty"
        fi
    done
    
    # Create htpasswd file using htpasswd or openssl
    if command -v htpasswd >/dev/null 2>&1; then
        htpasswd -bc "$htpasswd_file" "$flower_user" "$flower_pass"
    else
        # Fallback using openssl
        local salt=$(openssl rand -base64 6)
        local hashed_pass=$(openssl passwd -1 -salt "$salt" "$flower_pass")
        echo "$flower_user:$hashed_pass" > "$htpasswd_file"
    fi
    
    print_success "Created htpasswd file: $htpasswd_file"
}

# Function to bootstrap development environment
bootstrap_development() {
    print_message "Setting up development environment..."
    
    local env_file="${ENV_DIR}/.env.dev"
    local template_file="${ENV_DIR}/.env.dev.example"
    
    if [ ! -f "$template_file" ]; then
        print_error "Development template not found: $template_file"
        exit 1
    fi
    
    if ! check_file_exists "$env_file"; then
        print_message "Skipping development environment setup"
        return 0
    fi
    
    # Get development configuration
    local project_name=$(get_input "Enter project name" "LaunchKit")
    local project_slug=$(slugify "$project_name")
    
    local dev_api_url=$(get_input "Enter development API URL" "http://localhost:8000")
    local dev_app_url=$(get_input "Enter development app URL" "http://localhost:3000")
    
    # Generate development secret
    local dev_secret=$(generate_random_string)
    
    # Copy template and replace values
    cp "$template_file" "$env_file"
    
    # Replace values in the environment file
    sed -i.bak "s/PROJECT_NAME=launchkit/PROJECT_NAME=$project_name/" "$env_file"
    sed -i.bak "s/COMPOSE_PROJECT_NAME=launchkit-dev/COMPOSE_PROJECT_NAME=${project_slug}-dev/" "$env_file"
    sed -i.bak "s/DJANGO_SECRET_KEY=dev-change-me/DJANGO_SECRET_KEY=$dev_secret/" "$env_file"
    sed -i.bak "s|CSRF_TRUSTED_ORIGINS=http://localhost:3000|CSRF_TRUSTED_ORIGINS=$dev_app_url|" "$env_file"
    sed -i.bak "s|NEXT_PUBLIC_API_URL=http://localhost:8000|NEXT_PUBLIC_API_URL=$dev_api_url|" "$env_file"
    
    # Remove backup file
    rm -f "${env_file}.bak"
    
    print_success "Development environment configured: $env_file"
    return 0
}

# Function to bootstrap production environment
bootstrap_production() {
    print_message "Setting up production environment..."
    
    local env_file="${ENV_DIR}/.env.prod"
    local template_file="${ENV_DIR}/.env.prod.example"
    
    if [ ! -f "$template_file" ]; then
        print_error "Production template not found: $template_file"
        exit 1
    fi
    
    if ! check_file_exists "$env_file"; then
        print_message "Skipping production environment setup"
        return 0
    fi
    
    # Get production configuration
    local project_name=$(get_input "Enter project name" "LaunchKit")
    local project_slug=$(slugify "$project_name")
    
    # Get domain configuration
    local api_domain=""
    while [ -z "$api_domain" ] || ! validate_domain "$api_domain"; do
        api_domain=$(get_input "Enter API domain (e.g., api.example.com)" "")
        if [ -z "$api_domain" ]; then
            print_error "API domain cannot be empty"
        elif ! validate_domain "$api_domain"; then
            print_error "Invalid domain format: $api_domain"
        fi
    done
    
    local app_domain=""
    while [ -z "$app_domain" ] || ! validate_domain "$app_domain"; do
        app_domain=$(get_input "Enter app domain (e.g., app.example.com)" "")
        if [ -z "$app_domain" ]; then
            print_error "App domain cannot be empty"
        elif ! validate_domain "$app_domain"; then
            print_error "Invalid domain format: $app_domain"
        fi
    done
    
    local admin_email=""
    while [ -z "$admin_email" ]; do
        admin_email=$(get_input "Enter admin email for SSL certificates" "")
        if [ -z "$admin_email" ]; then
            print_error "Admin email cannot be empty"
        fi
    done
    
    # Generate production secrets
    local prod_secret=$(generate_random_string)
    local db_password=$(generate_random_string | cut -c1-16)
    local rabbitmq_password=$(generate_random_string | cut -c1-16)
    
    # Copy template and replace values
    cp "$template_file" "$env_file"
    
    # Replace values in the environment file
    sed -i.bak "s/PROJECT_NAME=launchkit/PROJECT_NAME=$project_name/" "$env_file"
    sed -i.bak "s/COMPOSE_PROJECT_NAME=launchkit-prod/COMPOSE_PROJECT_NAME=${project_slug}-prod/" "$env_file"
    sed -i.bak "s/DJANGO_SECRET_KEY=prod-change-me/DJANGO_SECRET_KEY=$prod_secret/" "$env_file"
    sed -i.bak "s/DJANGO_ALLOWED_HOSTS=api.example.com/DJANGO_ALLOWED_HOSTS=$api_domain/" "$env_file"
    sed -i.bak "s|CSRF_TRUSTED_ORIGINS=https://api.example.com,https://app.example.com|CSRF_TRUSTED_ORIGINS=https://$api_domain,https://$app_domain|" "$env_file"
    sed -i.bak "s/POSTGRES_PASSWORD=prod-change-me/POSTGRES_PASSWORD=$db_password/" "$env_file"
    sed -i.bak "s|DATABASE_URL=postgres://launchkit:prod-change-me@db:5432/launchkit_prod|DATABASE_URL=postgres://launchkit:$db_password@db:5432/launchkit_prod|" "$env_file"
    sed -i.bak "s/RABBITMQ_DEFAULT_PASS=prod-change-me/RABBITMQ_DEFAULT_PASS=$rabbitmq_password/" "$env_file"
    sed -i.bak "s|CELERY_BROKER_URL=amqp://launchkit:prod-change-me@amqp:5672//|CELERY_BROKER_URL=amqp://launchkit:$rabbitmq_password@amqp:5672//|" "$env_file"
    sed -i.bak "s|NEXT_PUBLIC_API_URL=https://api.example.com|NEXT_PUBLIC_API_URL=https://$api_domain|" "$env_file"
    sed -i.bak "s/PUBLIC_DOMAIN_API=api.example.com/PUBLIC_DOMAIN_API=$api_domain/" "$env_file"
    sed -i.bak "s/PUBLIC_DOMAIN_APP=app.example.com/PUBLIC_DOMAIN_APP=$app_domain/" "$env_file"
    sed -i.bak "s/ADMIN_EMAIL=admin@example.com/ADMIN_EMAIL=$admin_email/" "$env_file"
    sed -i.bak "s/DEFAULT_FROM_EMAIL=noreply@example.com/DEFAULT_FROM_EMAIL=noreply@$api_domain/" "$env_file"
    
    # Remove backup file
    rm -f "${env_file}.bak"
    
    # Create htpasswd file for Flower
    create_htpasswd
    
    print_success "Production environment configured: $env_file"
    return 0
}

# Function to write bootstrap state
write_bootstrap_state() {
    local project_name="$1"
    local project_slug="$2"
    local environment="$3"
    local env_file="$4"
    
    local state_file="${CONFIG_DIR}/.bootstrap_state.json"
    
    # Create config directory if it doesn't exist
    mkdir -p "$CONFIG_DIR"
    
    # Write state file
    cat > "$state_file" << EOF
{
  "project_name": "$project_name",
  "project_slug": "$project_slug",
  "environment": "$environment",
  "env_file": "$env_file",
  "generated_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    
    print_success "Bootstrap state written: $state_file"
}

# Main function
main() {
    print_message "LaunchKit Bootstrap Script"
    print_message "=========================="
    
    # Check if we're in the right directory
    if [ ! -f "${PROJECT_ROOT}/README.md" ]; then
        print_error "Please run this script from the LaunchKit project root"
        exit 1
    fi
    
    # Check for required commands
    local missing_commands=()
    for cmd in docker docker-compose; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        print_error "Missing required commands: ${missing_commands[*]}"
        print_message "Please install Docker and Docker Compose before running bootstrap"
        exit 1
    fi
    
    # Get project information
    local project_name=$(get_input "Enter project name" "LaunchKit")
    local project_slug=$(slugify "$project_name")
    
    # Get environment choice
    local environment=""
    while [ "$environment" != "development" ] && [ "$environment" != "production" ]; do
        environment=$(get_input "Choose environment (development/production)" "development")
        if [ "$environment" != "development" ] && [ "$environment" != "production" ]; then
            print_error "Please choose 'development' or 'production'"
        fi
    done
    
    # Bootstrap based on environment
    local env_file=""
    if [ "$environment" = "development" ]; then
        bootstrap_development
        env_file="${ENV_DIR}/.env.dev"
    else
        bootstrap_production
        env_file="${ENV_DIR}/.env.prod"
    fi
    
    # Write bootstrap state
    write_bootstrap_state "$project_name" "$project_slug" "$environment" "$env_file"
    
    # Print summary
    echo
    print_success "Bootstrap completed successfully!"
    echo
    print_message "Summary:"
    echo "  Project Name: $project_name"
    echo "  Project Slug: $project_slug"
    echo "  Environment: $environment"
    echo "  Environment File: $env_file"
    echo
    print_message "Next steps:"
    if [ "$environment" = "development" ]; then
        echo "  Run: ./scripts/run_dev.sh"
        echo "  API will be available at: http://localhost:8000"
        echo "  Frontend can be run locally with: cd app && npm run dev"
    else
        echo "  Run: ./scripts/run_prod.sh"
        echo "  Configure DNS records for: $api_domain and $app_domain"
        echo "  Obtain SSL certificates with: certbot --nginx -d $api_domain -d $app_domain"
    fi
    echo
}

# Run main function
main "$@"
