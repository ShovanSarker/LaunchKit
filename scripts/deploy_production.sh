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

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root"
        exit 1
    fi
}

# Function to check required commands
check_requirements() {
    print_message "Checking requirements..."
    
    # Basic requirements
    commands=("docker" "docker-compose" "git")
    
    # Add certbot to requirements if SSL is enabled
    if [ "$SSL_ENABLED" = true ]; then
        commands+=("certbot")
    fi
    
    for cmd in "${commands[@]}"; do
        if ! command -v $cmd &> /dev/null; then
            print_error "$cmd is required but not installed."
            exit 1
        fi
    done
}

# Function to load environment variables
load_env() {
    if [ -f .env ]; then
        set -a
        source .env
        set +a
    else
        print_error "Environment file .env not found"
        exit 1
    fi
}

# Function to setup SSL
setup_ssl() {
    if [ "$SSL_ENABLED" = true ]; then
        print_message "Setting up SSL..."
        
        # Install Certbot if not installed
        if ! command -v certbot &> /dev/null; then
            print_message "Installing Certbot..."
            apt-get update
            apt-get install -y certbot python3-certbot-nginx
        fi
        
        # Configure SSL
        print_message "Configuring SSL with Let's Encrypt..."
        certbot --nginx \
            -d ${DOMAIN} \
            -d www.${DOMAIN} \
            -d api.${DOMAIN} \
            -d monitor.${DOMAIN} \
            --non-interactive \
            --agree-tos \
            --email ${EMAIL}
    fi
}

# Function to check required files
check_required_files() {
    print_message "Checking required files..."
    
    # Check for docker-entrypoint.sh
    if [ ! -f "api/docker-entrypoint.sh" ]; then
        print_error "Docker entrypoint script not found at api/docker-entrypoint.sh"
        print_message "Creating docker entrypoint script..."
        
        # Create entrypoint script
        cat > api/docker-entrypoint.sh << EOL
#!/bin/bash
set -e

# Wait for database to be ready
echo "Waiting for database..."
while ! nc -z \$POSTGRES_HOST \$POSTGRES_PORT; do
  sleep 0.1
done
echo "Database is ready!"

# Run migrations
echo "Running migrations..."
python manage.py migrate

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Execute the command passed to docker run
exec "\$@"
EOL
        
        # Make the script executable
        chmod +x api/docker-entrypoint.sh
        print_message "Docker entrypoint script created successfully"
    fi
}

# Main function
main() {
    print_message "Starting production deployment..."
    
    # Check if running as root
    check_root
    
    # Load environment variables
    load_env
    
    # Check requirements
    check_requirements
    
    # Check required files
    check_required_files
    
    # Setup SSL if enabled
    setup_ssl
    
    # Build and start containers
    print_message "Building and starting containers..."
    cd docker && docker compose up -d --build
    
    # Check if containers are running
    print_message "Checking container status..."
    if docker compose ps | grep -q "Up"; then
        print_message "All containers are running successfully"
    else
        print_error "Some containers failed to start"
        exit 1
    fi
    
    print_message "Production deployment completed successfully!"
}

# Run main function
main 