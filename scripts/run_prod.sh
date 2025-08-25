#!/bin/bash

# =============================================================================
# LaunchKit Production Run Script
# =============================================================================
# Launches the full production stack with API, Next.js, Nginx, monitoring,
# and all supporting services.

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

# Function to print messages
print_message() {
    echo -e "${BLUE}[Prod]${NC} $1"
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

# Function to get compose project name from bootstrap state
get_compose_project_name() {
    local state_file="${CONFIG_DIR}/.bootstrap_state.json"
    local env_file="${ENV_DIR}/.env.prod"
    
    # Try to get from bootstrap state first
    if [ -f "$state_file" ] && command -v jq >/dev/null 2>&1; then
        local project_slug=$(jq -r '.project_slug' "$state_file" 2>/dev/null)
        if [ "$project_slug" != "null" ] && [ -n "$project_slug" ]; then
            echo "${project_slug}-prod"
            return 0
        fi
    fi
    
    # Fallback to environment file
    if [ -f "$env_file" ]; then
        local compose_name=$(grep "^COMPOSE_PROJECT_NAME=" "$env_file" | cut -d'=' -f2)
        if [ -n "$compose_name" ]; then
            echo "$compose_name"
            return 0
        fi
    fi
    
    # Final fallback
    echo "launchkit-prod"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to validate environment file
validate_env_file() {
    local env_file="${ENV_DIR}/.env.prod"
    
    if [ ! -f "$env_file" ]; then
        print_error "Production environment file not found: $env_file"
        print_message "Please run ./scripts/bootstrap.sh first to set up the production environment"
        exit 1
    fi
    
    # Check for required variables
    local missing_vars=()
    local required_vars=("DJANGO_SECRET_KEY" "POSTGRES_PASSWORD" "RABBITMQ_DEFAULT_PASS" "PUBLIC_DOMAIN_API" "PUBLIC_DOMAIN_APP" "ADMIN_EMAIL")
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}=" "$env_file" || grep -q "^${var}=.*change-me" "$env_file" || grep -q "^${var}=.*example.com" "$env_file"; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        print_error "Missing or invalid configuration in $env_file:"
        for var in "${missing_vars[@]}"; do
            echo "  - $var"
        done
        print_message "Please run ./scripts/bootstrap.sh to configure the environment"
        exit 1
    fi
}

# Function to check for port conflicts
check_port_conflicts() {
    local ports=("80" "443")
    local conflicts=()
    
    for port in "${ports[@]}"; do
        if lsof -i ":$port" >/dev/null 2>&1; then
            conflicts+=("$port")
        fi
    done
    
    if [ ${#conflicts[@]} -gt 0 ]; then
        print_warning "Port conflicts detected:"
        for port in "${conflicts[@]}"; do
            echo "  - Port $port is already in use"
        done
        print_message "You may need to stop conflicting services (like Apache/Nginx)"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to build images
build_images() {
    local env_file="${ENV_DIR}/.env.prod"
    local compose_file="${PROJECT_ROOT}/docker-compose.prod.yml"
    local project_name=$(get_compose_project_name)
    
    print_message "Building images..."
    
    # Set compose project name
    export COMPOSE_PROJECT_NAME="$project_name"
    
    # Build images
    docker compose --env-file "$env_file" -f "$compose_file" build
    
    print_success "Images built successfully"
}

# Function to start production stack
start_prod_stack() {
    local env_file="${ENV_DIR}/.env.prod"
    local compose_file="${PROJECT_ROOT}/docker-compose.prod.yml"
    local project_name=$(get_compose_project_name)
    
    print_message "Starting production stack..."
    print_message "Project: $project_name"
    print_message "Environment: $env_file"
    
    # Set compose project name
    export COMPOSE_PROJECT_NAME="$project_name"
    
    # Start the stack
    docker compose --env-file "$env_file" -f "$compose_file" up -d --remove-orphans
    
    print_success "Production stack started!"
}

# Function to wait for services to be ready
wait_for_services() {
    print_message "Waiting for services to be ready..."
    
    local project_name=$(get_compose_project_name)
    local env_file="${ENV_DIR}/.env.prod"
    local pg_user=$(grep "^POSTGRES_USER=" "$env_file" | cut -d'=' -f2)
    if [ -z "$pg_user" ]; then pg_user="launchkit"; fi
    
    # Wait for database
    print_message "Waiting for database..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker compose -p "$project_name" exec -T db pg_isready -U "$pg_user" >/dev/null 2>&1; then
            print_success "Database is ready"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_error "Database failed to start within $max_attempts seconds"
            exit 1
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    # Wait for Redis
    print_message "Waiting for Redis..."
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker compose -p "$project_name" exec -T redis redis-cli ping >/dev/null 2>&1; then
            print_success "Redis is ready"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_error "Redis failed to start within $max_attempts seconds"
            exit 1
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    # Wait for RabbitMQ
    print_message "Waiting for RabbitMQ..."
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker compose -p "$project_name" exec -T amqp rabbitmq-diagnostics ping >/dev/null 2>&1; then
            print_success "RabbitMQ is ready"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_error "RabbitMQ failed to start within $max_attempts seconds"
            exit 1
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    # Wait for API
    print_message "Waiting for API..."
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker compose -p "$project_name" exec -T api wget -qO- http://localhost:8000/api/health/ >/dev/null 2>&1; then
            print_success "API is ready"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_warning "API may still be starting up"
            break
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    # Wait for Next.js
    print_message "Waiting for Next.js..."
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if docker compose -p "$project_name" exec -T nextjs wget -qO- http://localhost:3000/api/health >/dev/null 2>&1; then
            print_success "Next.js is ready"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_warning "Next.js may still be starting up"
            break
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
    
    # Wait for Nginx
    print_message "Waiting for Nginx..."
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost/healthz >/dev/null 2>&1; then
            print_success "Nginx is ready"
            break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
            print_warning "Nginx may still be starting up"
            break
        fi
        
        echo -n "."
        sleep 2
        ((attempt++))
    done
}

# Function to sync Postgres role/database with env values
sync_postgres_credentials() {
    local project_name=$(get_compose_project_name)
    local env_file="${ENV_DIR}/.env.prod"
    local pg_user=$(grep "^POSTGRES_USER=" "$env_file" | cut -d'=' -f2)
    local pg_password=$(grep "^POSTGRES_PASSWORD=" "$env_file" | cut -d'=' -f2)
    local pg_db=$(grep "^POSTGRES_DB=" "$env_file" | cut -d'=' -f2)

    if [ -z "$pg_user" ] || [ -z "$pg_password" ] || [ -z "$pg_db" ]; then
        print_warning "Skipping Postgres sync (missing POSTGRES_* vars)."
        return 0
    fi

    print_message "Syncing Postgres credentials for role '$pg_user' and database '$pg_db'..."
    if ! docker compose -p "$project_name" exec -T db sh -lc "psql -U postgres -v ON_ERROR_STOP=1 <<'SQL'\nDO $$\nBEGIN\n   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$pg_user') THEN\n      CREATE ROLE $pg_user LOGIN PASSWORD '$pg_password';\n   ELSE\n      ALTER ROLE $pg_user WITH LOGIN PASSWORD '$pg_password';\n   END IF;\nEND\n$$;\n\nDO $$\nBEGIN\n   IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '$pg_db') THEN\n      CREATE DATABASE $pg_db OWNER $pg_user;\n   ELSE\n      ALTER DATABASE $pg_db OWNER TO $pg_user;\n   END IF;\nEND\n$$;\nSQL\n"; then
        print_warning "Postgres sync failed (continuing)."
    else
        print_success "Postgres credentials synced."
    fi
}

# Function to run post-deployment tasks
run_post_deployment_tasks() {
    local project_name=$(get_compose_project_name)
    
    print_message "Running post-deployment tasks..."
    
    # Ensure DB role/password/db match env before migrations
    sync_postgres_credentials

    # Run migrations
    print_message "Running database migrations..."
    if docker compose -p "$project_name" exec -T api python manage.py migrate --noinput; then
        print_success "Migrations completed"
    else
        print_warning "Migrations failed or not needed"
    fi
    
    # Collect static files
    print_message "Collecting static files..."
    if docker compose -p "$project_name" exec -T api python manage.py collectstatic --noinput; then
        print_success "Static files collected"
    else
        print_warning "Static file collection failed or not needed"
    fi
}

# Function to print service information
print_service_info() {
    local project_name=$(get_compose_project_name)
    local env_file="${ENV_DIR}/.env.prod"
    
    # Get domains from environment file
    local api_domain=$(grep "^PUBLIC_DOMAIN_API=" "$env_file" | cut -d'=' -f2)
    local app_domain=$(grep "^PUBLIC_DOMAIN_APP=" "$env_file" | cut -d'=' -f2)
    local enable_monitoring=$(grep "^ENABLE_MONITORING=" "$env_file" | cut -d'=' -f2)
    
    echo
    print_success "Production stack is running!"
    echo
    print_message "Services:"
    echo "  API:         https://$api_domain"
    echo "  API Health:  https://$api_domain/api/health/"
    echo "  API Docs:    https://$api_domain/api/docs/"
    echo "  Frontend:    https://$app_domain"
    echo "  Frontend Health: https://$app_domain/api/health"
    echo "  Flower:      https://$api_domain/flower/"
    
    if [ "$enable_monitoring" = "true" ]; then
        echo "  Uptime Kuma: http://localhost:3001"
        echo "  Dozzle:      http://localhost:9999"
    fi
    
    echo
    print_message "Useful commands:"
    echo "  View logs:   docker compose -p $project_name logs -f"
    echo "  API logs:    docker compose -p $project_name logs -f api"
    echo "  Nginx logs:  docker compose -p $project_name logs -f nginx"
    echo "  Stop stack:  docker compose -p $project_name down"
    echo
    print_message "SSL Certificates:"
    echo "  If you haven't obtained SSL certificates yet, run:"
    echo "  certbot --nginx -d $api_domain -d $app_domain"
    echo
    print_message "Next steps:"
    echo "  Create superuser: docker compose -p $project_name exec api python manage.py createsuperuser"
    echo "  Check logs: docker compose -p $project_name logs -f"
}

# Function to handle script arguments
handle_arguments() {
    case "${1:-}" in
        "stop")
            local project_name=$(get_compose_project_name)
            print_message "Stopping production stack..."
            docker compose -p "$project_name" down
            print_success "Production stack stopped"
            exit 0
            ;;
        "restart")
            local project_name=$(get_compose_project_name)
            print_message "Restarting production stack..."
            docker compose -p "$project_name" restart
            print_success "Production stack restarted"
            exit 0
            ;;
        "logs")
            local project_name=$(get_compose_project_name)
            docker compose -p "$project_name" logs -f "${@:2}"
            exit 0
            ;;
        "status")
            local project_name=$(get_compose_project_name)
            docker compose -p "$project_name" ps
            exit 0
            ;;
        "build")
            build_images
            exit 0
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [command]"
            echo
            echo "Commands:"
            echo "  (no args)  Start the production stack"
            echo "  stop       Stop the production stack"
            echo "  restart    Restart the production stack"
            echo "  logs       Show logs (optionally specify service)"
            echo "  status     Show service status"
            echo "  build      Build images"
            echo "  help       Show this help message"
            exit 0
            ;;
        "")
            # No arguments, continue with normal startup
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Main function
main() {
    print_message "LaunchKit Production Stack"
    print_message "=========================="
    
    # Handle command line arguments
    handle_arguments "$@"
    
    # Check if we're in the right directory
    if [ ! -f "${PROJECT_ROOT}/README.md" ]; then
        print_error "Please run this script from the LaunchKit project root"
        exit 1
    fi
    
    # Check Docker
    check_docker
    
    # Validate environment file
    validate_env_file
    
    # Check for port conflicts
    check_port_conflicts
    
    # Build images (if needed)
    build_images
    
    # Start the production stack
    start_prod_stack
    
    # Wait for services to be ready
    wait_for_services
    
    # Run post-deployment tasks
    run_post_deployment_tasks
    
    # Print service information
    print_service_info
}

# Run main function
main "$@"
