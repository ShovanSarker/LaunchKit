#!/bin/bash

# =============================================================================
# LaunchKit - Frontend Service Runner (Production)
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
    echo -e "${BLUE}[Frontend]${NC} $1"
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
    if [ ! -f "${PROJECT_ROOT}/app/.env.local" ]; then
        print_error "Frontend environment file not found: ${PROJECT_ROOT}/app/.env.local"
        print_message "Please run the setup script first: ./scripts/setup_server.sh"
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

# Check if backend is running
check_backend() {
    print_message "Checking if backend API is running..."
    if ! docker ps --format "{{.Names}}" | grep -q "${PROJECT_SLUG:-launchkit}_api"; then
        print_warning "Backend API is not running. Please start it first:"
        print_message "  ./run/production/run_backend.sh"
        exit 1
    fi
}

# Start frontend service
start_frontend() {
    print_message "Starting frontend service..."
    
    # Load environment variables
    source "${PROJECT_ROOT}/app/.env.local"
    
    # Check dependencies
    check_backend
    
    # Start frontend container
    cd "${PROJECT_ROOT}/docker"
    docker compose up -d frontend
    
    print_success "Frontend service started!"
    print_message "Frontend will be available at: https://${DOMAIN:-localhost}"
    
    # Show logs
    print_message "Showing frontend logs (Ctrl+C to stop):"
    docker compose logs -f frontend
}

# Stop frontend service
stop_frontend() {
    print_message "Stopping frontend service..."
    cd "${PROJECT_ROOT}/docker"
    docker compose stop frontend
    print_success "Frontend service stopped!"
}

# Restart frontend service
restart_frontend() {
    print_message "Restarting frontend service..."
    stop_frontend
    sleep 3
    start_frontend
}

# Show status
show_status() {
    print_message "Frontend service status:"
    cd "${PROJECT_ROOT}/docker"
    docker compose ps frontend
}

# Show logs
show_logs() {
    print_message "Showing frontend logs (Ctrl+C to stop):"
    cd "${PROJECT_ROOT}/docker"
    docker compose logs -f frontend
}

# Build frontend
build_frontend() {
    print_message "Building frontend application..."
    cd "${PROJECT_ROOT}/docker"
    docker compose build frontend
    print_success "Frontend build completed!"
}

# Main function
main() {
    case "${1:-start}" in
        "start")
            check_env
            check_docker
            start_frontend
            ;;
        "stop")
            stop_frontend
            ;;
        "restart")
            check_env
            check_docker
            restart_frontend
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "build")
            check_env
            check_docker
            build_frontend
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [start|stop|restart|status|logs|build|help]"
            echo ""
            echo "Commands:"
            echo "  start   - Start the frontend service (default)"
            echo "  stop    - Stop the frontend service"
            echo "  restart - Restart the frontend service"
            echo "  status  - Show frontend service status"
            echo "  logs    - Show frontend service logs"
            echo "  build   - Build frontend application"
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