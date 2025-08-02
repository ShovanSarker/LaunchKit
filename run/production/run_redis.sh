#!/bin/bash

# =============================================================================
# LaunchKit - Redis Service Runner (Development)
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
    echo -e "${BLUE}[Redis]${NC} $1"
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

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Start Redis service
start_redis() {
    print_message "Starting Redis service..."
    
    # Start Redis container
    cd "${PROJECT_ROOT}/docker"
    docker compose up -d redis
    
    print_success "Redis service started!"
    print_message "Redis will be available at: localhost:6379"
    
    # Show logs
    print_message "Showing Redis logs (Ctrl+C to stop):"
    docker compose logs -f redis
}

# Stop Redis service
stop_redis() {
    print_message "Stopping Redis service..."
    cd "${PROJECT_ROOT}/docker"
    docker compose stop redis
    print_success "Redis service stopped!"
}

# Restart Redis service
restart_redis() {
    print_message "Restarting Redis service..."
    stop_redis
    sleep 2
    start_redis
}

# Show status
show_status() {
    print_message "Redis service status:"
    cd "${PROJECT_ROOT}/docker"
    docker compose ps redis
}

# Show logs
show_logs() {
    print_message "Showing Redis logs (Ctrl+C to stop):"
    cd "${PROJECT_ROOT}/docker"
    docker compose logs -f redis
}

# Connect to Redis CLI
connect_cli() {
    print_message "Connecting to Redis CLI..."
    cd "${PROJECT_ROOT}/docker"
    docker compose exec redis redis-cli
}

# Main function
main() {
    case "${1:-start}" in
        "start")
            check_docker
            start_redis
            ;;
        "stop")
            stop_redis
            ;;
        "restart")
            check_docker
            restart_redis
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "cli")
            check_docker
            connect_cli
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [start|stop|restart|status|logs|cli|help]"
            echo ""
            echo "Commands:"
            echo "  start   - Start the Redis service (default)"
            echo "  stop    - Stop the Redis service"
            echo "  restart - Restart the Redis service"
            echo "  status  - Show Redis service status"
            echo "  logs    - Show Redis service logs"
            echo "  cli     - Connect to Redis CLI"
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