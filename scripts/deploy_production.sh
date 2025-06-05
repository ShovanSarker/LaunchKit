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

# Check AWS S3 buckets
check_s3_buckets() {
    print_message "Checking AWS S3 buckets..."
    
    # Get project name from .env or use default
    PROJECT_NAME=${PROJECT_NAME:-"launchkit"}
    
    # Define bucket names
    STATIC_BUCKET="${PROJECT_NAME}-static"
    MEDIA_BUCKET="${PROJECT_NAME}-media"
    
    print_message "Required S3 buckets:"
    print_message "1. Static files bucket: ${STATIC_BUCKET}"
    print_message "2. Media files bucket: ${MEDIA_BUCKET}"
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_message "Installing AWS CLI..."
        apt-get update
        apt-get install -y awscli
        
        # Configure AWS CLI if credentials are available
        if [ ! -z "$AWS_ACCESS_KEY_ID" ] && [ ! -z "$AWS_SECRET_ACCESS_KEY" ]; then
            aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
            aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
            aws configure set default.region ${AWS_S3_REGION_NAME}
        else
            print_warning "AWS credentials not found in environment. Please configure AWS CLI manually."
            return
        fi
    fi
    
    # Check if buckets exist
    if aws s3 ls "s3://${STATIC_BUCKET}" 2>&1 | grep -q 'NoSuchBucket'; then
        print_warning "Static bucket '${STATIC_BUCKET}' does not exist. Please create it."
    else
        print_message "Static bucket '${STATIC_BUCKET}' exists."
    fi
    
    if aws s3 ls "s3://${MEDIA_BUCKET}" 2>&1 | grep -q 'NoSuchBucket'; then
        print_warning "Media bucket '${MEDIA_BUCKET}' does not exist. Please create it."
    else
        print_message "Media bucket '${MEDIA_BUCKET}' exists."
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

# Setup database
setup_database() {
    print_message "Setting up database..."
    
    # Get database credentials from environment
    DB_NAME=${DB_NAME:-"launchkit"}
    DB_USER=${DB_USER:-"launchkit"}
    DB_PASSWORD=${DB_PASSWORD:-"your-password"}
    
    # Create database and user
    docker-compose -f docker-compose.prod.yml exec -T db psql -U postgres << EOF
    CREATE DATABASE ${DB_NAME};
    CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';
    GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
EOF
    
    if [ $? -ne 0 ]; then
        print_error "Database setup failed"
        exit 1
    fi
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
    docker-compose -f docker-compose.prod.yml up -d --build
    
    if [ $? -ne 0 ]; then
        print_error "Docker deployment failed"
        exit 1
    fi
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
    
    # Check frontend
    if curl -s -f "http://localhost:3000" > /dev/null; then
        print_message "Frontend is up and running"
    else
        print_error "Frontend health check failed"
        exit 1
    fi
    
    # Check backend
    if curl -s -f "http://localhost:8000/api/health/" > /dev/null; then
        print_message "Backend is up and running"
    else
        print_error "Backend health check failed"
        exit 1
    fi
    
    # Check database
    if docker-compose -f docker-compose.prod.yml exec -T db pg_isready -U ${DB_USER}; then
        print_message "Database is up and running"
    else
        print_error "Database health check failed"
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
    
    # Check S3 buckets
    check_s3_buckets
    
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