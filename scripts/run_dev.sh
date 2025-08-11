#!/bin/bash

# =============================================================================
# LaunchKit Development Run Script
# =============================================================================
# Launches the full development stack with database, Redis, RabbitMQ, API,
# worker, and scheduler services.

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
    echo -e "${BLUE}[Dev]${NC} $1"
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
    local env_file="${ENV_DIR}/.env.dev"
    
    # Try to get from bootstrap state first
    if [ -f "$state_file" ] && command -v jq >/dev/null 2>&1; then
        local project_slug=$(jq -r '.project_slug' "$state_file" 2>/dev/null)
        if [ "$project_slug" != "null" ] && [ -n "$project_slug" ]; then
            echo "${project_slug}-dev"
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
    echo "launchkit-dev"
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
    local env_file="${ENV_DIR}/.env.dev"
    
    if [ ! -f "$env_file" ]; then
        print_error "Development environment file not found: $env_file"
        print_message "Please run ./scripts/bootstrap.sh first to set up the development environment"
        exit 1
    fi
    
    # Check for required variables
    local missing_vars=()
    local required_vars=("DJANGO_SECRET_KEY" "POSTGRES_PASSWORD" "RABBITMQ_DEFAULT_PASS")
    
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}=" "$env_file" || grep -q "^${var}=.*change-me" "$env_file"; then
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
    local ports=("8000" "5432" "6379" "5672" "15672")
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
        print_message "You may need to stop conflicting services or change port mappings"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Function to start development stack
start_dev_stack() {
    local env_file="${ENV_DIR}/.env.dev"
    local compose_file="${PROJECT_ROOT}/docker-compose.dev.yml"
    local project_name=$(get_compose_project_name)
    
    print_message "Starting development stack..."
    print_message "Project: $project_name"
    print_message "Environment: $env_file"
    
    # Set compose project name
    export COMPOSE_PROJECT_NAME="$project_name"
    
    # Start the stack
    docker compose --env-file "$env_file" -f "$compose_file" up -d --remove-orphans
    
    print_success "Development stack started!"
}

# Function to wait for services to be ready
wait_for_services() {
    print_message "Waiting for services to be ready..."
    
    local project_name=$(get_compose_project_name)
    
    # Wait for database
    print_message "Waiting for database..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker compose -p "$project_name" exec -T db pg_isready -U postgres >/dev/null 2>&1; then
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
        if curl -s http://localhost:8000/api/health/ >/dev/null 2>&1; then
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
}

# Function to run database migrations
run_migrations() {
    local project_name=$(get_compose_project_name)
    
    print_message "Running database migrations..."
    
    if docker compose -p "$project_name" exec -T api python manage.py migrate --noinput; then
        print_success "Migrations completed"
    else
        print_warning "Migrations failed or not needed"
    fi
}

# Function to print service information
print_service_info() {
    local project_name=$(get_compose_project_name)
    
    echo
    print_success "Development stack is running!"
    echo
    print_message "Services:"
    echo "  API:         http://localhost:8000"
    echo "  API Health:  http://localhost:8000/api/health/"
    echo "  API Docs:    http://localhost:8000/api/docs/"
    echo "  Database:    localhost:5432 (postgres/postgres)"
    echo "  Redis:       localhost:6379"
    echo "  RabbitMQ:    localhost:5672"
    echo "  RabbitMQ UI: http://localhost:15672 (guest/guest)"
    echo
    print_message "Useful commands:"
    echo "  View logs:   docker compose -p $project_name logs -f"
    echo "  API logs:    docker compose -p $project_name logs -f api"
    echo "  Worker logs: docker compose -p $project_name logs -f worker"
    echo "  Stop stack:  docker compose -p $project_name down"
    echo
    print_message "Next steps:"
    echo "  Start Next.js frontend: cd app && npm run dev"
    echo "  Create superuser: docker compose -p $project_name exec api python manage.py createsuperuser"
    echo "  Shell access: docker compose -p $project_name exec api python manage.py shell"
}

# Function to handle script arguments
handle_arguments() {
    case "${1:-}" in
        "stop")
            local project_name=$(get_compose_project_name)
            print_message "Stopping development stack..."
            docker compose -p "$project_name" down
            print_success "Development stack stopped"
            exit 0
            ;;
        "restart")
            local project_name=$(get_compose_project_name)
            print_message "Restarting development stack..."
            docker compose -p "$project_name" restart
            print_success "Development stack restarted"
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
        "help"|"-h"|"--help")
            echo "Usage: $0 [command]"
            echo
            echo "Commands:"
            echo "  (no args)  Start the development stack"
            echo "  stop       Stop the development stack"
            echo "  restart    Restart the development stack"
            echo "  logs       Show logs (optionally specify service)"
            echo "  status     Show service status"
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
    print_message "LaunchKit Development Stack"
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
    
    # Start the development stack
    start_dev_stack
    
    # Wait for services to be ready
    wait_for_services
    
    # Run migrations
    run_migrations
    
    # Print service information
    print_service_info
}

# Run main function
main "$@"
