#!/bin/bash

# =============================================================================
# LaunchKit - Nginx Service Runner (Production)
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
    echo -e "${BLUE}[Nginx]${NC} $1"
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
    if [ ! -f "${PROJECT_ROOT}/docker/.env" ]; then
        print_error "Docker environment file not found: ${PROJECT_ROOT}/docker/.env"
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

# Check if frontend is running
check_frontend() {
    print_message "Checking if frontend is running..."
    if ! docker ps --format "{{.Names}}" | grep -q "${PROJECT_SLUG:-launchkit}_frontend"; then
        print_warning "Frontend is not running. Please start it first:"
        print_message "  ./run/production/run_frontend.sh"
        exit 1
    fi
}

# Start Nginx service
start_nginx() {
    print_message "Starting Nginx service..."
    
    # Load environment variables
    source "${PROJECT_ROOT}/docker/.env"
    
    # Check dependencies
    check_backend
    check_frontend
    
    # Start Nginx container
    cd "${PROJECT_ROOT}/docker"
    docker compose up -d nginx
    
    print_success "Nginx service started!"
    print_message "Nginx will be available at:"
    print_message "  • Main site: https://${DOMAIN:-localhost}"
    print_message "  • API: https://api.${DOMAIN:-localhost}"
    print_message "  • Monitoring: https://monitor.${DOMAIN:-localhost}"
    
    # Show logs
    print_message "Showing Nginx logs (Ctrl+C to stop):"
    docker compose logs -f nginx
}

# Stop Nginx service
stop_nginx() {
    print_message "Stopping Nginx service..."
    cd "${PROJECT_ROOT}/docker"
    docker compose stop nginx
    print_success "Nginx service stopped!"
}

# Restart Nginx service
restart_nginx() {
    print_message "Restarting Nginx service..."
    stop_nginx
    sleep 3
    start_nginx
}

# Show status
show_status() {
    print_message "Nginx service status:"
    cd "${PROJECT_ROOT}/docker"
    docker compose ps nginx
}

# Show logs
show_logs() {
    print_message "Showing Nginx logs (Ctrl+C to stop):"
    cd "${PROJECT_ROOT}/docker"
    docker compose logs -f nginx
}

# Test Nginx configuration
test_config() {
    print_message "Testing Nginx configuration..."
    cd "${PROJECT_ROOT}/docker"
    docker compose exec nginx nginx -t
    print_success "Nginx configuration is valid!"
}

# Reload Nginx configuration
reload_config() {
    print_message "Reloading Nginx configuration..."
    cd "${PROJECT_ROOT}/docker"
    docker compose exec nginx nginx -s reload
    print_success "Nginx configuration reloaded!"
}

# Main function
main() {
    case "${1:-start}" in
        "start")
            check_env
            check_docker
            start_nginx
            ;;
        "stop")
            stop_nginx
            ;;
        "restart")
            check_env
            check_docker
            restart_nginx
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "test")
            check_env
            check_docker
            test_config
            ;;
        "reload")
            check_env
            check_docker
            reload_config
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [start|stop|restart|status|logs|test|reload|help]"
            echo ""
            echo "Commands:"
            echo "  start   - Start the Nginx service (default)"
            echo "  stop    - Stop the Nginx service"
            echo "  restart - Restart the Nginx service"
            echo "  status  - Show Nginx service status"
            echo "  logs    - Show Nginx service logs"
            echo "  test    - Test Nginx configuration"
            echo "  reload  - Reload Nginx configuration"
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