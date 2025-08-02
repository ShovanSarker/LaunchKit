#!/bin/bash

# =============================================================================
# LaunchKit - RabbitMQ Service Runner (Development)
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
    echo -e "${BLUE}[RabbitMQ]${NC} $1"
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

# Start RabbitMQ service
start_rabbitmq() {
    print_message "Starting RabbitMQ service..."
    
    # Start RabbitMQ container
    cd "${PROJECT_ROOT}/docker"
    docker compose up -d rabbitmq
    
    print_success "RabbitMQ service started!"
    print_message "RabbitMQ will be available at: localhost:5672"
    print_message "RabbitMQ Management UI: http://localhost:15672"
    
    # Show logs
    print_message "Showing RabbitMQ logs (Ctrl+C to stop):"
    docker compose logs -f rabbitmq
}

# Stop RabbitMQ service
stop_rabbitmq() {
    print_message "Stopping RabbitMQ service..."
    cd "${PROJECT_ROOT}/docker"
    docker compose stop rabbitmq
    print_success "RabbitMQ service stopped!"
}

# Restart RabbitMQ service
restart_rabbitmq() {
    print_message "Restarting RabbitMQ service..."
    stop_rabbitmq
    sleep 2
    start_rabbitmq
}

# Show status
show_status() {
    print_message "RabbitMQ service status:"
    cd "${PROJECT_ROOT}/docker"
    docker compose ps rabbitmq
}

# Show logs
show_logs() {
    print_message "Showing RabbitMQ logs (Ctrl+C to stop):"
    cd "${PROJECT_ROOT}/docker"
    docker compose logs -f rabbitmq
}

# Open management UI
open_ui() {
    print_message "Opening RabbitMQ Management UI..."
    if command -v open > /dev/null 2>&1; then
        open http://localhost:15672
    elif command -v xdg-open > /dev/null 2>&1; then
        xdg-open http://localhost:15672
    else
        print_message "Please open http://localhost:15672 in your browser"
    fi
}

# Main function
main() {
    case "${1:-start}" in
        "start")
            check_docker
            start_rabbitmq
            ;;
        "stop")
            stop_rabbitmq
            ;;
        "restart")
            check_docker
            restart_rabbitmq
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "ui")
            open_ui
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [start|stop|restart|status|logs|ui|help]"
            echo ""
            echo "Commands:"
            echo "  start   - Start the RabbitMQ service (default)"
            echo "  stop    - Stop the RabbitMQ service"
            echo "  restart - Restart the RabbitMQ service"
            echo "  status  - Show RabbitMQ service status"
            echo "  logs    - Show RabbitMQ service logs"
            echo "  ui      - Open RabbitMQ Management UI"
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