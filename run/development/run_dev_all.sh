#!/bin/bash

# =============================================================================
# LaunchKit - Development Environment Runner
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
    echo -e "${BLUE}[Dev]${NC} $1"
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

# Start all development services
start_all() {
    print_message "Starting all development services..."
    
    # Load environment variables
    source "${PROJECT_ROOT}/api/.env"
    
    # Start all services
    cd "${PROJECT_ROOT}/docker"
    docker compose up -d
    
    print_success "All development services started!"
    print_message ""
    print_message "Services available at:"
    print_message "  • API:         http://localhost:8000"
    print_message "  • API Docs:    http://localhost:8000/api/docs/"
    print_message "  • PostgreSQL:  localhost:5432"
    print_message "  • Redis:       localhost:6379"
    print_message "  • RabbitMQ:    localhost:5672"
    print_message "  • RabbitMQ UI: http://localhost:15672"
    print_message ""
    print_message "Next steps:"
    print_message "  • Start Next.js app: cd app && npm run dev"
    print_message "  • View logs: docker compose logs -f"
    print_message "  • Stop all: docker compose down"
}

# Stop all development services
stop_all() {
    print_message "Stopping all development services..."
    cd "${PROJECT_ROOT}/docker"
    docker compose down
    print_success "All development services stopped!"
}

# Restart all development services
restart_all() {
    print_message "Restarting all development services..."
    stop_all
    sleep 3
    start_all
}

# Show status of all services
show_status() {
    print_message "Development services status:"
    cd "${PROJECT_ROOT}/docker"
    docker compose ps
}

# Show logs of all services
show_logs() {
    print_message "Showing logs for all services (Ctrl+C to stop):"
    cd "${PROJECT_ROOT}/docker"
    docker compose logs -f
}

# Show logs for specific service
show_service_logs() {
    local service=$1
    if [ -z "$service" ]; then
        print_error "Please specify a service name"
        echo "Available services: api, worker, scheduler, postgres, redis, rabbitmq"
        exit 1
    fi
    
    print_message "Showing logs for $service (Ctrl+C to stop):"
    cd "${PROJECT_ROOT}/docker"
    docker compose logs -f "$service"
}

# Main function
main() {
    case "${1:-start}" in
        "start")
            check_env
            check_docker
            start_all
            ;;
        "stop")
            stop_all
            ;;
        "restart")
            check_env
            check_docker
            restart_all
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "logs")
            show_service_logs "$2"
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [start|stop|restart|status|logs|logs <service>|help]"
            echo ""
            echo "Commands:"
            echo "  start           - Start all development services (default)"
            echo "  stop            - Stop all development services"
            echo "  restart         - Restart all development services"
            echo "  status          - Show status of all services"
            echo "  logs            - Show logs for all services"
            echo "  logs <service>  - Show logs for specific service"
            echo "  help            - Show this help message"
            echo ""
            echo "Available services: api, worker, scheduler, postgres, redis, rabbitmq"
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