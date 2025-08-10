#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Function to print messages
print_message() {
    echo -e "${BLUE}[Setup]${NC} $1"
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

# Function to get user input with default value
get_input() {
    local prompt="$1"
    local default="$2"
    local input
    
    read -p "$prompt [$default]: " input
    echo "${input:-$default}"
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root (use sudo)"
        exit 1
    fi
}

# Function to install system dependencies
install_system_dependencies() {
    print_message "Installing system dependencies..."
    
    # Update package lists
    apt-get update
    
    # Install required packages
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common \
        git \
        nginx \
        ufw \
        fail2ban \
        nodejs \
        npm \
        python3 \
        python3-pip \
        python3-venv \
        apache2-utils
    
    print_success "System dependencies installed"
}

# Function to install Docker
install_docker() {
    print_message "Installing Docker..."
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package lists
    apt-get update
    
    # Install Docker
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    # Add current user to docker group
    usermod -aG docker $SUDO_USER
    
    print_success "Docker installed and configured"
}

# Function to configure firewall
configure_firewall() {
    print_message "Configuring firewall..."
    
    # Reset UFW to defaults
    ufw --force reset
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH
    ufw allow ssh
    
    # Allow HTTP and HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Enable UFW
    ufw --force enable
    
    print_success "Firewall configured"
}

# Function to configure Fail2ban
configure_fail2ban() {
    print_message "Configuring Fail2ban..."
    
    # Create custom jail configuration
    cat > /etc/fail2ban/jail.local << EOL
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 3
EOL
    
    # Restart Fail2ban
    systemctl restart fail2ban
    systemctl enable fail2ban
    
    print_success "Fail2ban configured"
}

# Function to create environment templates
create_environment_templates() {
    print_message "Creating environment templates..."
    
    # Create templates directory if it doesn't exist
    mkdir -p "${PROJECT_ROOT}/templates/env/production"
    
    # Create API environment template
    cat > "${PROJECT_ROOT}/templates/env/production/api.env.template" << 'EOL'
# =============================================================================
# LaunchKit - API Environment Configuration (Production)
# =============================================================================
# Copy this file to api/.env and update the values below

# =============================================================================
# PROJECT SETTINGS
# =============================================================================
# TODO: Update these with your project information
PROJECT_NAME=LaunchKit
PROJECT_SLUG=launchkit

# =============================================================================
# DJANGO SETTINGS
# =============================================================================
# TODO: Set to 'production' for production deployment
DJANGO_ENV=production

# TODO: Set to False in production
DEBUG=False

# TODO: Generate a secure secret key (use: openssl rand -base64 32)
DJANGO_SECRET_KEY=your-secret-key-here

# TODO: Add your domain names (comma-separated)
ALLOWED_HOSTS=your-domain.com,api.your-domain.com,www.your-domain.com

# TODO: Add your frontend URLs (comma-separated)
CSRF_TRUSTED_ORIGINS=https://your-domain.com,https://api.your-domain.com

# =============================================================================
# DATABASE SETTINGS
# =============================================================================
# TODO: Update with your database credentials
POSTGRES_DB=launchkit
POSTGRES_USER=launchkit
POSTGRES_PASSWORD=your-db-password-here
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# =============================================================================
# REDIS SETTINGS
# =============================================================================
# TODO: Update Redis URL if using external Redis
REDIS_URL=redis://redis:6379/0

# =============================================================================
# RABBITMQ SETTINGS
# =============================================================================
# TODO: Update with your RabbitMQ credentials
CELERY_BROKER_URL=amqp://launchkit:password@rabbitmq:5672/launchkit
CELERY_RESULT_BACKEND=redis://redis:6379/0

# =============================================================================
# EMAIL SETTINGS (PRODUCTION)
# =============================================================================
# TODO: Configure your email backend
EMAIL_BACKEND=sendgrid_backend.SendgridBackend
SENDGRID_API_KEY=your-sendgrid-api-key-here
SENDGRID_FROM_EMAIL=your-email@your-domain.com

# Alternative email backends:
# EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
# EMAIL_HOST=smtp.gmail.com
# EMAIL_PORT=587
# EMAIL_USE_TLS=True
# EMAIL_HOST_USER=your-email@gmail.com
# EMAIL_HOST_PASSWORD=your-app-password

# =============================================================================
# FRONTEND URL
# =============================================================================
# TODO: Update with your frontend URL
FRONTEND_URL=https://your-domain.com

# =============================================================================
# LOGGING SETTINGS
# =============================================================================
LOG_LEVEL=INFO
LOG_FILE=/var/log/launchkit/api.log

# =============================================================================
# SECURITY SETTINGS
# =============================================================================
# TODO: Configure security settings
SECURE_SSL_REDIRECT=True
SECURE_HSTS_SECONDS=31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS=True
SECURE_HSTS_PRELOAD=True
SECURE_CONTENT_TYPE_NOSNIFF=True
SECURE_BROWSER_XSS_FILTER=True
X_FRAME_OPTIONS=DENY

# =============================================================================
# CORS SETTINGS
# =============================================================================
# TODO: Add your frontend domain
CORS_ALLOWED_ORIGINS=https://your-domain.com
CORS_ALLOW_CREDENTIALS=True

# =============================================================================
# JWT SETTINGS
# =============================================================================
# TODO: Generate secure JWT keys
JWT_SECRET_KEY=your-jwt-secret-key-here
JWT_ACCESS_TOKEN_LIFETIME=5
JWT_REFRESH_TOKEN_LIFETIME=1

# =============================================================================
# MONITORING SETTINGS
# =============================================================================
# TODO: Configure monitoring endpoints
PROMETHEUS_METRICS_EXPORT_PORT=8001
PROMETHEUS_METRICS_EXPORT_ADDRESS=0.0.0.0
EOL

    # Create Frontend environment template
    cat > "${PROJECT_ROOT}/templates/env/production/app.env.template" << 'EOL'
# =============================================================================
# LaunchKit - Frontend Environment Configuration (Production)
# =============================================================================
# Copy this file to app/.env.local and update the values below

# =============================================================================
# PROJECT INFORMATION
# =============================================================================
# TODO: Update with your project information
NEXT_PUBLIC_PROJECT_NAME=LaunchKit
NEXT_PUBLIC_PROJECT_SLUG=launchkit

# =============================================================================
# API SETTINGS
# =============================================================================
# TODO: Update with your API URL
NEXT_PUBLIC_API_URL=https://api.your-domain.com

# =============================================================================
# AUTHENTICATION SETTINGS
# =============================================================================
# TODO: Update with your domain
NEXTAUTH_URL=https://your-domain.com

# TODO: Generate a secure secret (use: openssl rand -base64 32)
NEXTAUTH_SECRET=your-nextauth-secret-here

# =============================================================================
# FEATURE FLAGS
# =============================================================================
# TODO: Configure feature flags based on your needs
NEXT_PUBLIC_FEATURE_REGISTRATION_ENABLED=true
NEXT_PUBLIC_FEATURE_SOCIAL_LOGIN_ENABLED=false
NEXT_PUBLIC_FEATURE_EMAIL_VERIFICATION_ENABLED=true
NEXT_PUBLIC_FEATURE_PASSWORD_RESET_ENABLED=true

# =============================================================================
# ANALYTICS SETTINGS
# =============================================================================
# TODO: Add your analytics configuration
NEXT_PUBLIC_GOOGLE_ANALYTICS_ID=
NEXT_PUBLIC_MIXPANEL_TOKEN=

# =============================================================================
# MONITORING SETTINGS
# =============================================================================
# TODO: Configure monitoring endpoints
NEXT_PUBLIC_MONITORING_URL=https://monitor.your-domain.com
NEXT_PUBLIC_HEALTH_CHECK_URL=https://api.your-domain.com/api/health/

# =============================================================================
# DEVELOPMENT SETTINGS
# =============================================================================
# TODO: Set to false in production
NODE_ENV=production
NEXT_PUBLIC_DEBUG_MODE=false
EOL

    # Create Docker environment template
    cat > "${PROJECT_ROOT}/templates/env/production/docker.env.template" << 'EOL'
# =============================================================================
# LaunchKit - Docker Environment Configuration (Production)
# =============================================================================
# Copy this file to docker/.env and update the values below

# =============================================================================
# PROJECT SETTINGS
# =============================================================================
# TODO: Update with your project information
PROJECT_NAME=LaunchKit
PROJECT_SLUG=launchkit

# =============================================================================
# DOMAIN SETTINGS
# =============================================================================
# TODO: Update with your domain
DOMAIN=your-domain.com
EMAIL=admin@your-domain.com

# =============================================================================
# DATABASE SETTINGS
# =============================================================================
# TODO: Update with your database credentials
POSTGRES_DB=launchkit
POSTGRES_USER=launchkit
POSTGRES_PASSWORD=your-db-password-here

# =============================================================================
# RABBITMQ SETTINGS
# =============================================================================
# TODO: Update with your RabbitMQ credentials
RABBITMQ_DEFAULT_USER=launchkit
RABBITMQ_DEFAULT_PASS=your-rabbitmq-password-here
RABBITMQ_DEFAULT_VHOST=launchkit

# =============================================================================
# MONITORING SETTINGS
# =============================================================================
# TODO: Update with your monitoring credentials
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=your-grafana-password-here

# =============================================================================
# SSL SETTINGS
# =============================================================================
# TODO: Configure SSL settings
SSL_ENABLED=true
SSL_EMAIL=admin@your-domain.com

# =============================================================================
# BACKUP SETTINGS
# =============================================================================
# TODO: Configure backup settings
BACKUP_ENABLED=true
BACKUP_RETENTION_DAYS=30
BACKUP_SCHEDULE=0 2 * * *

# =============================================================================
# SECURITY SETTINGS
# =============================================================================
# TODO: Configure security settings
FAIL2BAN_ENABLED=true
UFW_ENABLED=true
SECURITY_HEADERS_ENABLED=true

# =============================================================================
# PERFORMANCE SETTINGS
# =============================================================================
# TODO: Configure performance settings
NGINX_WORKER_PROCESSES=auto
NGINX_WORKER_CONNECTIONS=1024
NGINX_KEEPALIVE_TIMEOUT=65
NGINX_CLIENT_MAX_BODY_SIZE=10M
EOL

    print_success "Environment templates created"
}

# Function to create run scripts
create_run_scripts() {
    print_message "Creating run scripts..."
    
    # Create run directories
    mkdir -p "${PROJECT_ROOT}/run/development"
    mkdir -p "${PROJECT_ROOT}/run/production"
    
    # Make scripts executable
    chmod +x "${PROJECT_ROOT}/run/development"/*.sh 2>/dev/null || true
    chmod +x "${PROJECT_ROOT}/run/production"/*.sh 2>/dev/null || true
    
    print_success "Run scripts directory structure created"
}

# Function to display next steps
display_next_steps() {
    print_success "Server setup completed!"
    echo ""
    echo "Next steps:"
    echo "1. Configure environment files:"
    echo "   cp templates/env/production/api.env.template api/.env"
    echo "   cp templates/env/production/app.env.template app/.env.local"
    echo "   cp templates/env/production/docker.env.template docker/.env"
    echo ""
    echo "2. Edit the environment files with your values"
    echo ""
    echo "3. Configure DNS records:"
    echo "   A     your-domain.com        → $(curl -s ifconfig.me)"
    echo "   A     api.your-domain.com    → $(curl -s ifconfig.me)"
    echo "   A     monitor.your-domain.com → $(curl -s ifconfig.me)"
    echo ""
    echo "4. Start production services:"
    echo "   ./run/production/run_prod_all.sh"
    echo ""
    echo "5. Run post-deployment tasks:"
    echo "   ./run/production/run_backend.sh migrate"
    echo "   ./run/production/run_backend.sh createsuperuser"
    echo ""
    echo "6. View the setup guide for detailed instructions:"
    echo "   cat run/SETUP_GUIDE.md"
    echo ""
}

# Main function
main() {
    print_message "Starting LaunchKit server setup..."
    
    # Check if running as root
    check_root
    
    # Install system dependencies
    install_system_dependencies
    
    # Install Docker
    install_docker
    
    # Configure firewall
    configure_firewall
    
    # Configure Fail2ban
    configure_fail2ban
    
    # Create environment templates
    create_environment_templates
    
    # Create run scripts
    create_run_scripts
    
    # Display next steps
    display_next_steps
}

# Run main function
main "$@" 