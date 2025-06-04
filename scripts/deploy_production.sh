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
    
    commands=("docker" "docker-compose" "git")
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
        exit 1
    fi
    
    source .env
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
        print_warning "AWS CLI not installed. Cannot verify bucket existence."
        return
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
}

# Main deployment process
main() {
    print_message "Starting production deployment..."
    
    # Check requirements
    check_requirements
    
    # Load environment variables
    load_env
    
    # Check S3 buckets
    check_s3_buckets
    
    # Pull latest changes
    pull_latest_changes
    
    # Deploy frontend
    deploy_frontend
    
    # Deploy backend
    deploy_backend
    
    # Deploy with Docker
    deploy_docker
    
    # Health check
    health_check
    
    print_message "Deployment completed successfully!"
}

# Run main function
main 