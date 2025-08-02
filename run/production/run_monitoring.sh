#!/bin/bash

# =============================================================================
# LaunchKit - Monitoring Service Runner (Production)
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
    echo -e "${BLUE}[Monitoring]${NC} $1"
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

# Start monitoring services
start_monitoring() {
    print_message "Starting monitoring services..."
    
    # Load environment variables
    source "${PROJECT_ROOT}/docker/.env"
    
    # Start monitoring containers
    cd "${PROJECT_ROOT}/docker"
    docker compose up -d prometheus grafana cadvisor node-exporter
    
    print_success "Monitoring services started!"
    print_message "Monitoring will be available at:"
    print_message "  • Grafana: https://monitor.${DOMAIN:-localhost}"
    print_message "  • Prometheus: http://localhost:9090"
    print_message "  • cAdvisor: http://localhost:8080"
    
    # Show logs
    print_message "Showing monitoring logs (Ctrl+C to stop):"
    docker compose logs -f prometheus grafana cadvisor node-exporter
}

# Stop monitoring services
stop_monitoring() {
    print_message "Stopping monitoring services..."
    cd "${PROJECT_ROOT}/docker"
    docker compose stop prometheus grafana cadvisor node-exporter
    print_success "Monitoring services stopped!"
}

# Restart monitoring services
restart_monitoring() {
    print_message "Restarting monitoring services..."
    stop_monitoring
    sleep 3
    start_monitoring
}

# Show status
show_status() {
    print_message "Monitoring services status:"
    cd "${PROJECT_ROOT}/docker"
    docker compose ps prometheus grafana cadvisor node-exporter
}

# Show logs
show_logs() {
    print_message "Showing monitoring logs (Ctrl+C to stop):"
    cd "${PROJECT_ROOT}/docker"
    docker compose logs -f prometheus grafana cadvisor node-exporter
}

# Show logs for specific service
show_service_logs() {
    local service=$1
    if [ -z "$service" ]; then
        print_error "Please specify a service name"
        echo "Available services: prometheus, grafana, cadvisor, node-exporter"
        exit 1
    fi
    
    print_message "Showing logs for $service (Ctrl+C to stop):"
    cd "${PROJECT_ROOT}/docker"
    docker compose logs -f "$service"
}

# Open Grafana UI
open_grafana() {
    print_message "Opening Grafana UI..."
    local url="https://monitor.${DOMAIN:-localhost}"
    if command -v open > /dev/null 2>&1; then
        open "$url"
    elif command -v xdg-open > /dev/null 2>&1; then
        xdg-open "$url"
    else
        print_message "Please open $url in your browser"
    fi
}

# Open Prometheus UI
open_prometheus() {
    print_message "Opening Prometheus UI..."
    if command -v open > /dev/null 2>&1; then
        open http://localhost:9090
    elif command -v xdg-open > /dev/null 2>&1; then
        xdg-open http://localhost:9090
    else
        print_message "Please open http://localhost:9090 in your browser"
    fi
}

# Main function
main() {
    case "${1:-start}" in
        "start")
            check_env
            check_docker
            start_monitoring
            ;;
        "stop")
            stop_monitoring
            ;;
        "restart")
            check_env
            check_docker
            restart_monitoring
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
        "grafana")
            open_grafana
            ;;
        "prometheus")
            open_prometheus
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [start|stop|restart|status|logs|logs <service>|grafana|prometheus|help]"
            echo ""
            echo "Commands:"
            echo "  start           - Start all monitoring services (default)"
            echo "  stop            - Stop all monitoring services"
            echo "  restart         - Restart all monitoring services"
            echo "  status          - Show status of all monitoring services"
            echo "  logs            - Show logs for all monitoring services"
            echo "  logs <service>  - Show logs for specific service"
            echo "  grafana         - Open Grafana UI"
            echo "  prometheus      - Open Prometheus UI"
            echo "  help            - Show this help message"
            echo ""
            echo "Available services: prometheus, grafana, cadvisor, node-exporter"
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