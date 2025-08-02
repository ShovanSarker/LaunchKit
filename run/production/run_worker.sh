#!/bin/bash

# =============================================================================
# LaunchKit - Celery Worker Runner (Development)
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
    echo -e "${BLUE}[Worker]${NC} $1"
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

# Start worker service
start_worker() {
    print_message "Starting Celery worker service..."
    
    # Load environment variables
    source "${PROJECT_ROOT}/api/.env"
    
    # Check dependencies
    check_redis
    check_rabbitmq
    
    # Start worker container
    cd "${PROJECT_ROOT}/docker"
    docker compose up -d worker
    
    print_success "Celery worker service started!"
    print_message "Worker will process background tasks from RabbitMQ"
    
    # Show logs
    print_message "Showing worker logs (Ctrl+C to stop):"
    docker compose logs -f worker
}

# Stop worker service
stop_worker() {
    print_message "Stopping Celery worker service..."
    cd "${PROJECT_ROOT}/docker"
    docker compose stop worker
    print_success "Celery worker service stopped!"
}

# Restart worker service
restart_worker() {
    print_message "Restarting Celery worker service..."
    stop_worker
    sleep 2
    start_worker
}

# Show status
show_status() {
    print_message "Worker service status:"
    cd "${PROJECT_ROOT}/docker"
    docker compose ps worker
}

# Show logs
show_logs() {
    print_message "Showing worker logs (Ctrl+C to stop):"
    cd "${PROJECT_ROOT}/docker"
    docker compose logs -f worker
}

# Main function
main() {
    case "${1:-start}" in
        "start")
            check_env
            check_docker
            start_worker
            ;;
        "stop")
            stop_worker
            ;;
        "restart")
            check_env
            check_docker
            restart_worker
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
            echo "  start   - Start the Celery worker service (default)"
            echo "  stop    - Stop the Celery worker service"
            echo "  restart - Restart the Celery worker service"
            echo "  status  - Show worker service status"
            echo "  logs    - Show worker service logs"
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