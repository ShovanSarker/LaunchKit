#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print messages
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if required commands exist
check_requirements() {
    print_message "Checking requirements..."
    
    commands=("docker" "docker-compose" "git" "certbot")
    for cmd in "${commands[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            print_error "$cmd is required but not installed."
            exit 1
        fi
    done
}

# Load environment variables
load_env() {
    print_message "Loading environment variables..."
    
    if [ ! -f .env ]; then
        print_error ".env file not found!"
        print_message "Please run ./scripts/setup_env.sh first to create the environment files."
        exit 1
    fi
    
    # Load environment variables
    set -a
    source .env
    set +a
    
    # Check required variables
    if [ -z "$DOMAIN" ]; then
        print_error "DOMAIN is not set in .env file"
        print_message "Please run ./scripts/setup_env.sh to set up your environment variables."
        exit 1
    fi
    
    if [ -z "$EMAIL" ]; then
        print_error "EMAIL is not set in .env file"
        print_message "Please run ./scripts/setup_env.sh to set up your environment variables."
        exit 1
    fi
    
    print_message "Environment variables loaded successfully"
    print_message "Domain: ${DOMAIN}"
    print_message "Email: ${EMAIL}"
}

# Check storage buckets
check_storage_buckets() {
    print_message "Checking storage buckets..."
    
    # Get project name from .env or use default
    PROJECT_NAME=${PROJECT_NAME:-"launchkit"}
    
    # Define bucket names
    STATIC_BUCKET="${PROJECT_NAME}-static"
    MEDIA_BUCKET="${PROJECT_NAME}-media"
    
    print_message "Required storage buckets:"
    print_message "1. Static files bucket: ${STATIC_BUCKET}"
    print_message "2. Media files bucket: ${MEDIA_BUCKET}"
    
    # Check if using DO Spaces
    if [ ! -z "$AWS_S3_ENDPOINT_URL" ] && [[ "$AWS_S3_ENDPOINT_URL" == *"digitaloceanspaces.com"* ]]; then
        print_message "Using DigitalOcean Spaces"
        print_message "Please ensure you have created the following Spaces:"
        print_message "1. ${STATIC_BUCKET}"
        print_message "2. ${MEDIA_BUCKET}"
        print_message "You can create them at: https://cloud.digitalocean.com/spaces"
    else
        print_message "Using AWS S3"
        print_message "Please ensure you have created the following S3 buckets:"
        print_message "1. ${STATIC_BUCKET}"
        print_message "2. ${MEDIA_BUCKET}"
    fi
}

# Setup SSL certificates
setup_ssl() {
    print_message "Setting up SSL certificates..."
    
    # Get domain and email from environment
    if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
        print_error "DOMAIN or EMAIL not set in environment"
        print_message "Please run ./scripts/setup_env.sh to set up your environment variables."
        exit 1
    fi
    
    # Install Certbot if not installed
    if ! command -v certbot &> /dev/null; then
        print_message "Installing Certbot..."
        apt-get update
        apt-get install -y certbot python3-certbot-nginx
    fi
    
    # Obtain SSL certificates
    print_message "Obtaining SSL certificates for domain: ${DOMAIN}"
    certbot --nginx \
        -d ${DOMAIN} \
        -d www.${DOMAIN} \
        -d api.${DOMAIN} \
        -d monitor.${DOMAIN} \
        --email ${EMAIL} \
        --agree-tos \
        --non-interactive
    
    if [ $? -ne 0 ]; then
        print_error "SSL certificate setup failed"
        exit 1
    fi
    
    print_message "SSL certificates obtained successfully"
}

# Create docker-compose file
create_docker_compose() {
    print_message "Creating Docker Compose file..."
    
    # Create docker directory if it doesn't exist
    mkdir -p "${PROJECT_ROOT}/docker"
    
    docker_compose_file="${PROJECT_ROOT}/docker/docker-compose.prod.yml"
    
    if [ ! -f "$docker_compose_file" ]; then
        cat > "$docker_compose_file" << EOF
version: '3.8'

services:
  # API service
  api:
    build:
      context: ../api
      dockerfile: Dockerfile
    container_name: ${PROJECT_SLUG}_api
    volumes:
      - ../api:/app
    env_file:
      - ../api/.env
    environment:
      - DJANGO_SETTINGS_MODULE=project.settings.production
      - DEBUG=False
      - POSTGRES_HOST=postgres
      - POSTGRES_DB=\${POSTGRES_DB}
      - POSTGRES_USER=\${POSTGRES_USER}
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
    depends_on:
      - postgres
      - redis
      - rabbitmq
    restart: unless-stopped

  # Celery Worker
  worker:
    build:
      context: ../api
      dockerfile: Dockerfile
    container_name: ${PROJECT_SLUG}_worker
    volumes:
      - ../api:/app
    env_file:
      - ../api/.env
    environment:
      - DJANGO_SETTINGS_MODULE=project.settings.production
      - DEBUG=False
      - POSTGRES_HOST=postgres
      - POSTGRES_DB=\${POSTGRES_DB}
      - POSTGRES_USER=\${POSTGRES_USER}
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
    depends_on:
      - postgres
      - redis
      - rabbitmq
    command: celery -A project worker --loglevel=info
    restart: unless-stopped

  # Celery Beat Scheduler
  scheduler:
    build:
      context: ../api
      dockerfile: Dockerfile
    container_name: ${PROJECT_SLUG}_scheduler
    volumes:
      - ../api:/app
    env_file:
      - ../api/.env
    environment:
      - DJANGO_SETTINGS_MODULE=project.settings.production
      - DEBUG=False
      - POSTGRES_HOST=postgres
      - POSTGRES_DB=\${POSTGRES_DB}
      - POSTGRES_USER=\${POSTGRES_USER}
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
    depends_on:
      - postgres
      - redis
      - rabbitmq
    command: celery -A project beat --loglevel=info
    restart: unless-stopped

  # Database service
  postgres:
    image: postgres:15-alpine
    container_name: ${PROJECT_SLUG}_postgres
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=\${POSTGRES_DB}
      - POSTGRES_USER=\${POSTGRES_USER}
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  # Redis for caching and Celery results backend
  redis:
    image: redis:7-alpine
    container_name: ${PROJECT_SLUG}_redis
    volumes:
      - redisdata:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  # RabbitMQ for message broker
  rabbitmq:
    image: rabbitmq:3-management-alpine
    container_name: ${PROJECT_SLUG}_rabbitmq
    environment:
      - RABBITMQ_DEFAULT_USER=\${RABBITMQ_DEFAULT_USER}
      - RABBITMQ_DEFAULT_PASS=\${RABBITMQ_DEFAULT_PASS}
      - RABBITMQ_DEFAULT_VHOST=\${RABBITMQ_DEFAULT_VHOST}
    ports:
      - "5672:5672"
      - "15672:15672"
    healthcheck:
      test: ["CMD", "rabbitmq-diagnostics", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  # Nginx for reverse proxy
  nginx:
    image: nginx:alpine
    container_name: ${PROJECT_SLUG}_nginx
    volumes:
      - ../nginx/conf.d:/etc/nginx/conf.d
      - ../nginx/ssl:/etc/nginx/ssl
      - ../api/static:/app/static
      - ../api/media:/app/media
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - api
    restart: unless-stopped

volumes:
  pgdata:
  redisdata:

networks:
  default:
    name: ${PROJECT_SLUG}_network
EOF
        print_success "Created: $docker_compose_file"
    fi
}

# Setup database
setup_database() {
    print_message "Setting up database..."
    
    # Create docker directory if it doesn't exist
    mkdir -p docker
    
    # Create docker-compose file
    create_docker_compose
    
    # Create required directories
    mkdir -p nginx/conf.d nginx/ssl
    
    # Start database container
    print_message "Starting database container..."
    cd docker && docker-compose -f docker-compose.prod.yml up -d postgres
    
    # Wait for database to be ready
    print_message "Waiting for database to be ready..."
    sleep 10
    
    # Verify database connection
    print_message "Verifying database connection..."
    if docker-compose -f docker-compose.prod.yml exec -T postgres psql -U ${DB_USER} -d ${DB_NAME} -c "\l" > /dev/null 2>&1; then
        print_message "Database connection successful"
    else
        print_error "Database connection failed"
        print_message "Please check if:"
        print_message "1. Docker is running"
        print_message "2. Environment variables are set correctly"
        print_message "3. Port 5432 is available"
        exit 1
    fi
    
    cd ..
}

# Pull latest changes
pull_latest_changes() {
    print_message "Pulling latest changes..."
    
    git pull origin main
    if [ $? -ne 0 ]; then
        print_error "Failed to pull latest changes"
        exit 1
    fi
}

# Build and deploy frontend
deploy_frontend() {
    print_message "Deploying frontend..."
    
    cd app
    
    # Install dependencies
    print_message "Installing frontend dependencies..."
    npm install
    
    # Build frontend
    print_message "Building frontend..."
    npm run build
    
    if [ $? -ne 0 ]; then
        print_error "Frontend build failed"
        exit 1
    fi
    
    cd ..
}

# Build and deploy backend
deploy_backend() {
    print_message "Deploying backend..."
    
    cd api
    
    # Install dependencies
    print_message "Installing backend dependencies..."
    pip install -r requirements/prod.txt
    
    # Run migrations
    print_message "Running database migrations..."
    python manage.py migrate
    
    # Collect static files
    print_message "Collecting static files..."
    python manage.py collectstatic --noinput
    
    cd ..
}

# Deploy with Docker
deploy_docker() {
    print_message "Deploying with Docker..."
    
    # Build and start containers
    cd docker && docker-compose -f docker-compose.prod.yml up -d --build
    
    if [ $? -ne 0 ]; then
        print_error "Docker deployment failed"
        exit 1
    fi
    
    cd ..
}

# Verify security
verify_security() {
    print_message "Verifying security configuration..."
    
    # Check firewall rules
    print_message "Checking firewall rules..."
    ufw status
    
    # Verify Nginx configuration
    print_message "Verifying Nginx configuration..."
    nginx -t
    
    # Test SSL configuration
    print_message "Testing SSL configuration..."
    curl -I https://${DOMAIN}
}

# Verify backups
verify_backups() {
    print_message "Verifying backup configuration..."
    
    # Check backup service status
    print_message "Checking backup service status..."
    systemctl status backup.service
    
    # List available backups
    print_message "Listing available backups..."
    ls -l /backup/
}

# Setup monitoring
setup_monitoring() {
    print_message "Setting up monitoring..."
    
    # Access Grafana and set up dashboards
    print_message "Setting up Grafana dashboards..."
    
    # Wait for Grafana to be ready
    sleep 10
    
    # Import dashboards
    for dashboard in monitoring/dashboards/*.json; do
        print_message "Importing dashboard: ${dashboard}"
        curl -X POST \
            -H "Content-Type: application/json" \
            -d @${dashboard} \
            http://admin:admin@localhost:3000/api/dashboards/db
    done
    
    # Set up alerts
    print_message "Setting up monitoring alerts..."
    for alert in monitoring/alerts/*.json; do
        print_message "Importing alert: ${alert}"
        curl -X POST \
            -H "Content-Type: application/json" \
            -d @${alert} \
            http://admin:admin@localhost:3000/api/alerts
    done
}

# Health check
health_check() {
    print_message "Performing health check..."
    
    # Wait for services to be ready
    sleep 10
    
    # Check API
    if curl -s -f "http://localhost:8000/api/health/" > /dev/null; then
        print_message "API is up and running"
    else
        print_error "API health check failed"
        exit 1
    fi
    
    # Check database
    if docker-compose -f docker/docker-compose.prod.yml exec -T postgres pg_isready -U ${DB_USER}; then
        print_message "Database is up and running"
    else
        print_error "Database health check failed"
        exit 1
    fi
    
    # Check Redis
    if docker-compose -f docker/docker-compose.prod.yml exec -T redis redis-cli ping | grep -q "PONG"; then
        print_message "Redis is up and running"
    else
        print_error "Redis health check failed"
        exit 1
    fi
    
    # Check RabbitMQ
    if docker-compose -f docker/docker-compose.prod.yml exec -T rabbitmq rabbitmq-diagnostics ping | grep -q "Ping succeeded"; then
        print_message "RabbitMQ is up and running"
    else
        print_error "RabbitMQ health check failed"
        exit 1
    fi
}

# Main deployment process
main() {
    print_message "Starting production deployment..."
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root"
        exit 1
    fi
    
    # Check requirements
    check_requirements
    
    # Load environment variables
    load_env
    
    # Check storage buckets
    check_storage_buckets
    
    # Setup SSL certificates
    setup_ssl
    
    # Setup database
    setup_database
    
    # Pull latest changes
    pull_latest_changes
    
    # Deploy frontend
    deploy_frontend
    
    # Deploy backend
    deploy_backend
    
    # Deploy with Docker
    deploy_docker
    
    # Verify security
    verify_security
    
    # Verify backups
    verify_backups
    
    # Setup monitoring
    setup_monitoring
    
    # Health check
    health_check
    
    print_message "Deployment completed successfully!"
    print_message "Please check the following:"
    print_message "1. SSL certificates are properly configured"
    print_message "2. Database is accessible and migrations are applied"
    print_message "3. Static files are collected and served"
    print_message "4. Monitoring dashboards are set up"
    print_message "5. Backup system is working"
    print_message "6. Security measures are in place"
}

# Run main function
main 