#!/bin/bash

# =============================================================================
# LaunchKit - Production Environment Runner
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
    echo -e "${BLUE}[Prod]${NC} $1"
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
        print_message "Please run the setup script first: ./scripts/setup_server.sh"
        exit 1
    fi
    
    if [ ! -f "${PROJECT_ROOT}/app/.env.local" ]; then
        print_error "Frontend environment file not found: ${PROJECT_ROOT}/app/.env.local"
        print_message "Please run the setup script first: ./scripts/setup_server.sh"
        exit 1
    fi
    
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

# Start all production services
start_all() {
    print_message "Starting all production services..."
    
    # Load environment variables
    source "${PROJECT_ROOT}/docker/.env"
    
    # Start all services
    cd "${PROJECT_ROOT}/docker"
    docker compose up -d
    
    print_success "All production services started!"
    print_message ""
    print_message "Services available at:"
    print_message "  • Main site: https://${DOMAIN:-localhost}"
    print_message "  • API: https://api.${DOMAIN:-localhost}"
    print_message "  • API Docs: https://api.${DOMAIN:-localhost}/api/docs/"
    print_message "  • Monitoring: https://monitor.${DOMAIN:-localhost}"
    print_message ""
    print_message "Database and Message Brokers:"
    print_message "  • PostgreSQL: localhost:5432"
    print_message "  • Redis: localhost:6379"
    print_message "  • RabbitMQ: localhost:5672"
    print_message "  • RabbitMQ UI: http://localhost:15672"
    print_message ""
    print_message "Monitoring:"
    print_message "  • Prometheus: http://localhost:9090"
    print_message "  • cAdvisor: http://localhost:8080"
    print_message ""
    print_message "Next steps:"
    print_message "  • Run migrations: ./run/production/run_backend.sh migrate"
    print_message "  • Create superuser: ./run/production/run_backend.sh createsuperuser"
    print_message "  • View logs: docker compose logs -f"
    print_message "  • Stop all: docker compose down"
}

# Stop all production services
stop_all() {
    print_message "Stopping all production services..."
    cd "${PROJECT_ROOT}/docker"
    docker compose down
    print_success "All production services stopped!"
}

# Restart all production services
restart_all() {
    print_message "Restarting all production services..."
    stop_all
    sleep 5
    start_all
}

# Show status of all services
show_status() {
    print_message "Production services status:"
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
        echo "Available services: api, frontend, worker, scheduler, db, redis, rabbitmq, nginx, prometheus, grafana, cadvisor, node-exporter"
        exit 1
    fi
    
    print_message "Showing logs for $service (Ctrl+C to stop):"
    cd "${PROJECT_ROOT}/docker"
    docker compose logs -f "$service"
}

# Run migrations
run_migrations() {
    print_message "Running database migrations..."
    cd "${PROJECT_ROOT}/docker"
    docker compose exec api python manage.py migrate
    print_success "Migrations completed!"
}

# Collect static files
collect_static() {
    print_message "Collecting static files..."
    cd "${PROJECT_ROOT}/docker"
    docker compose exec api python manage.py collectstatic --noinput
    print_success "Static files collected!"
}

# Create superuser
create_superuser() {
    print_message "Creating superuser..."
    cd "${PROJECT_ROOT}/docker"
    docker compose exec api python manage.py createsuperuser
}

# Health check
health_check() {
    print_message "Performing health checks..."
    
    # Check if containers are running
    cd "${PROJECT_ROOT}/docker"
    local containers=$(docker compose ps --format "{{.Name}}" --filter "status=running")
    local total_containers=$(echo "$containers" | wc -l)
    
    print_message "Found $total_containers running containers:"
    echo "$containers"
    
    # Check API health
    print_message "Checking API health..."
    if curl -f -s "https://api.${DOMAIN:-localhost}/api/health/" > /dev/null; then
        print_success "API is healthy"
    else
        print_warning "API health check failed"
    fi
    
    # Check frontend health
    print_message "Checking frontend health..."
    if curl -f -s "https://${DOMAIN:-localhost}" > /dev/null; then
        print_success "Frontend is healthy"
    else
        print_warning "Frontend health check failed"
    fi
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
        "migrate")
            check_env
            check_docker
            run_migrations
            ;;
        "collectstatic")
            check_env
            check_docker
            collect_static
            ;;
        "createsuperuser")
            check_env
            check_docker
            create_superuser
            ;;
        "health")
            check_env
            check_docker
            health_check
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [start|stop|restart|status|logs|logs <service>|migrate|collectstatic|createsuperuser|health|help]"
            echo ""
            echo "Commands:"
            echo "  start           - Start all production services (default)"
            echo "  stop            - Stop all production services"
            echo "  restart         - Restart all production services"
            echo "  status          - Show status of all services"
            echo "  logs            - Show logs for all services"
            echo "  logs <service>  - Show logs for specific service"
            echo "  migrate         - Run database migrations"
            echo "  collectstatic   - Collect static files"
            echo "  createsuperuser - Create Django superuser"
            echo "  health          - Perform health checks"
            echo "  help            - Show this help message"
            echo ""
            echo "Available services: api, frontend, worker, scheduler, db, redis, rabbitmq, nginx, prometheus, grafana, cadvisor, node-exporter"
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