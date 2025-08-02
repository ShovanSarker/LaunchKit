#!/bin/bash

# =============================================================================
# LaunchKit - Backend Service Runner (Development)
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

# Function to print messages
print_message() {
    echo -e "${BLUE}[Backend]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if .env file exists
check_env() {
    if [ ! -f "${PROJECT_ROOT}/api/.env" ]; then
        print_error "API environment file not found: ${PROJECT_ROOT}/api/.env"
        print_message "Please run the setup script first: ./scripts/setup_development.sh"
        exit 1
    fi
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Check if database is running
check_database() {
    print_message "Checking if database is running..."
    if ! docker ps --format "{{.Names}}" | grep -q "${PROJECT_SLUG:-launchkit}_postgres"; then
        print_warning "Database container is not running. Starting database..."
        cd "${PROJECT_ROOT}/docker" && docker compose up -d postgres
        sleep 5
    fi
}

# Check if Redis is running
check_redis() {
    print_message "Checking if Redis is running..."
    if ! docker ps --format "{{.Names}}" | grep -q "${PROJECT_SLUG:-launchkit}_redis"; then
        print_warning "Redis container is not running. Starting Redis..."
        cd "${PROJECT_ROOT}/docker" && docker compose up -d redis
        sleep 3
    fi
}

# Check if RabbitMQ is running
check_rabbitmq() {
    print_message "Checking if RabbitMQ is running..."
    if ! docker ps --format "{{.Names}}" | grep -q "${PROJECT_SLUG:-launchkit}_rabbitmq"; then
        print_warning "RabbitMQ container is not running. Starting RabbitMQ..."
        cd "${PROJECT_ROOT}/docker" && docker compose up -d rabbitmq
        sleep 5
    fi
}

# Start backend service
start_backend() {
    print_message "Starting backend API service..."
    
    # Load environment variables
    source "${PROJECT_ROOT}/api/.env"
    
    # Check dependencies
    check_database
    check_redis
    check_rabbitmq
    
    # Start backend container
    cd "${PROJECT_ROOT}/docker"
    docker compose up -d api
    
    print_success "Backend API service started!"
    print_message "API will be available at: http://localhost:8000"
    print_message "API Documentation: http://localhost:8000/api/docs/"
    
    # Show logs
    print_message "Showing backend logs (Ctrl+C to stop):"
    docker compose logs -f api
}

# Stop backend service
stop_backend() {
    print_message "Stopping backend API service..."
    cd "${PROJECT_ROOT}/docker"
    docker compose stop api
    print_success "Backend API service stopped!"
}

# Restart backend service
restart_backend() {
    print_message "Restarting backend API service..."
    stop_backend
    sleep 2
    start_backend
}

# Show status
show_status() {
    print_message "Backend service status:"
    cd "${PROJECT_ROOT}/docker"
    docker compose ps api
}

# Show logs
show_logs() {
    print_message "Showing backend logs (Ctrl+C to stop):"
    cd "${PROJECT_ROOT}/docker"
    docker compose logs -f api
}

# Main function
main() {
    case "${1:-start}" in
        "start")
            check_env
            check_docker
            start_backend
            ;;
        "stop")
            stop_backend
            ;;
        "restart")
            check_env
            check_docker
            restart_backend
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [start|stop|restart|status|logs|help]"
            echo ""
            echo "Commands:"
            echo "  start   - Start the backend API service (default)"
            echo "  stop    - Stop the backend API service"
            echo "  restart - Restart the backend API service"
            echo "  status  - Show backend service status"
            echo "  logs    - Show backend service logs"
            echo "  help    - Show this help message"
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 