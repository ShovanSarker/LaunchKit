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
        print_error "Please run as root"
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
        prometheus \
        nodejs \
        npm \
        python3 \
        python3-pip \
        python3-venv
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
    apt-get install -y docker-ce docker-ce-cli containerd.io
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
}

# Function to configure firewall
configure_firewall() {
    print_message "Configuring firewall..."
    
    # Reset firewall to default
    ufw --force reset
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH
    ufw allow ssh
    
    # Allow HTTP and HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Enable firewall
    ufw --force enable
}

# Function to setup Nginx
setup_nginx() {
    print_message "Setting up Nginx..."
    
    # Get domain information
    BASE_DOMAIN=$(get_input "Enter your base domain (e.g., example.com)" "example.com")
    
    # Remove default configuration
    rm -f /etc/nginx/sites-enabled/default
    
    # Create main application Nginx configuration
    cat > /etc/nginx/sites-available/launchkit << EOL
# Main frontend server
server {
    listen 80;
    server_name ${BASE_DOMAIN} www.${BASE_DOMAIN};

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

# API server
server {
    listen 80;
    server_name api.${BASE_DOMAIN};

    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'none'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # CORS headers
    add_header 'Access-Control-Allow-Origin' 'https://${BASE_DOMAIN}' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
    add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;

    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=api_limit:10m rate=10r/s;
    limit_req zone=api_limit burst=20 nodelay;

    # API endpoints
    location / {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Handle OPTIONS method for CORS
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' 'https://${BASE_DOMAIN}' always;
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain; charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }
}

# Monitoring server
server {
    listen 80;
    server_name monitor.${BASE_DOMAIN};

    # Basic auth for monitoring
    auth_basic "Monitoring Access";
    auth_basic_user_file /etc/nginx/.htpasswd;

    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Prometheus
    location /prometheus {
        proxy_pass http://localhost:9090;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Grafana
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL
    
    # Enable the site
    ln -s /etc/nginx/sites-available/launchkit /etc/nginx/sites-enabled/
    
    # Create basic auth for monitoring
    print_message "Creating monitoring access credentials..."
    MONITOR_USER=$(get_input "Enter monitoring username" "admin")
    MONITOR_PASS=$(get_input "Enter monitoring password" "monitor123")
    htpasswd -bc /etc/nginx/.htpasswd "$MONITOR_USER" "$MONITOR_PASS"
    
    # Update environment templates with the domain
    sed -i "s/example.com/${BASE_DOMAIN}/g" templates/env/production/api.env.template
    sed -i "s/example.com/${BASE_DOMAIN}/g" templates/env/production/app.env.template
    
    # Test Nginx configuration
    nginx -t
    
    # Reload Nginx
    systemctl reload nginx
    
    print_message "Nginx configured for domain: ${BASE_DOMAIN}"
    print_message "Frontend will be available at: https://${BASE_DOMAIN}"
    print_message "API will be available at: https://api.${BASE_DOMAIN}"
    print_message "Monitoring will be available at: https://monitor.${BASE_DOMAIN}"
}

# Function to setup monitoring
setup_monitoring() {
    print_message "Setting up monitoring..."
    
    # Create Prometheus configuration
    cat > /etc/prometheus/prometheus.yml << 'EOL'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'launchkit'
    static_configs:
      - targets: 
        - 'localhost:8000'  # Django API
        - 'localhost:3000'  # Next.js Frontend
        - 'localhost:5432'  # PostgreSQL
        - 'localhost:6379'  # Redis
        - 'localhost:5672'  # RabbitMQ
        - 'localhost:15672' # RabbitMQ Management
    metrics_path: '/metrics'
    scheme: 'http'

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['localhost:8080']
EOL
    
    # Install Node Exporter for system metrics
    apt-get install -y prometheus-node-exporter
    
    # Install cAdvisor for container metrics
    docker run -d \
        --name=cadvisor \
        --restart=always \
        -p 8080:8080 \
        -v /:/rootfs:ro \
        -v /var/run:/var/run:ro \
        -v /sys:/sys:ro \
        -v /var/lib/docker/:/var/lib/docker:ro \
        -v /dev/disk/:/dev/disk:ro \
        gcr.io/cadvisor/cadvisor:latest
    
    # Start Prometheus
    systemctl enable prometheus
    systemctl start prometheus
    
    # Install and configure Grafana
    apt-get install -y apt-transport-https software-properties-common
    wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
    echo "deb https://packages.grafana.com/oss/deb stable main" | tee -a /etc/apt/sources.list.d/grafana.list
    apt-get update
    apt-get install -y grafana
    
    # Configure Grafana
    cat > /etc/grafana/grafana.ini << 'EOL'
[server]
http_port = 3000
domain = monitor.example.com  # Will be replaced with actual domain
root_url = https://monitor.example.com/  # Will be replaced with actual domain

[security]
admin_user = admin
admin_password = admin  # Should be changed after first login

[auth.anonymous]
enabled = false

[auth.basic]
enabled = true
EOL
    
    # Start Grafana
    systemctl enable grafana-server
    systemctl start grafana-server
}

# Function to setup object storage
setup_object_storage() {
    print_message "Setting up object storage..."
    
    # Ask for storage provider
    STORAGE_PROVIDER=$(get_input "Choose storage provider (aws/do)" "aws")
    
    if [ "$STORAGE_PROVIDER" = "aws" ]; then
        # AWS S3 Configuration
        print_message "Configuring AWS S3..."
        AWS_ACCESS_KEY=$(get_input "Enter AWS Access Key ID" "")
        AWS_SECRET_KEY=$(get_input "Enter AWS Secret Access Key" "")
        AWS_BUCKET_NAME=$(get_input "Enter S3 Bucket Name" "")
        AWS_REGION=$(get_input "Enter AWS Region" "us-east-1")
        
        # Print AWS S3 setup instructions
        print_message "AWS S3 Setup Instructions:"
        echo "1. Create an S3 bucket:"
        echo "   - Go to AWS S3 Console: https://s3.console.aws.amazon.com"
        echo "   - Click 'Create bucket'"
        echo "   - Enter bucket name: ${AWS_BUCKET_NAME}"
        echo "   - Select region: ${AWS_REGION}"
        echo "   - Uncheck 'Block all public access'"
        echo "   - Enable versioning (recommended)"
        echo "   - Click 'Create bucket'"
        echo ""
        echo "2. Configure bucket policy:"
        echo "   - Select your bucket"
        echo "   - Go to 'Permissions' tab"
        echo "   - Click 'Bucket Policy'"
        echo "   - Add the following policy:"
        cat > /tmp/bucket-policy.json << EOL
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${AWS_BUCKET_NAME}/*"
        }
    ]
}
EOL
        cat /tmp/bucket-policy.json
        echo ""
        echo "3. Configure CORS:"
        echo "   - Go to 'Permissions' tab"
        echo "   - Click 'CORS configuration'"
        echo "   - Add the following configuration:"
        cat > /tmp/cors-config.json << EOL
[
    {
        "AllowedHeaders": [
            "*"
        ],
        "AllowedMethods": [
            "GET",
            "HEAD",
            "PUT",
            "POST",
            "DELETE"
        ],
        "AllowedOrigins": [
            "https://${BASE_DOMAIN}",
            "https://www.${BASE_DOMAIN}",
            "https://api.${BASE_DOMAIN}"
        ],
        "ExposeHeaders": [
            "ETag"
        ],
        "MaxAgeSeconds": 3600
    }
]
EOL
        cat /tmp/cors-config.json
        echo ""
        echo "4. Enable static website hosting (optional):"
        echo "   - Go to 'Properties' tab"
        echo "   - Scroll to 'Static website hosting'"
        echo "   - Click 'Enable'"
        echo "   - Enter 'index.html' for both Index and Error documents"
        echo ""
        
        # Update environment template with AWS settings
        cat >> templates/env/production/api.env.template << EOL

# AWS S3 Storage
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_KEY}
AWS_STORAGE_BUCKET_NAME=${AWS_BUCKET_NAME}
AWS_S3_REGION_NAME=${AWS_REGION}
AWS_S3_CUSTOM_DOMAIN=s3.${AWS_REGION}.amazonaws.com
AWS_DEFAULT_ACL=public-read
AWS_S3_OBJECT_PARAMETERS={"CacheControl": "max-age=86400"}
AWS_QUERYSTRING_AUTH=False
AWS_S3_FILE_OVERWRITE=False
AWS_S3_VERIFY=True
AWS_S3_SIGNATURE_VERSION=s3v4
EOL

    elif [ "$STORAGE_PROVIDER" = "do" ]; then
        # DigitalOcean Spaces Configuration
        print_message "Configuring DigitalOcean Spaces..."
        DO_SPACES_KEY=$(get_input "Enter DO Spaces Key" "")
        DO_SPACES_SECRET=$(get_input "Enter DO Spaces Secret" "")
        DO_SPACES_NAME=$(get_input "Enter DO Spaces Name" "")
        DO_SPACES_REGION=$(get_input "Enter DO Spaces Region" "nyc3")
        
        # Print DO Spaces setup instructions
        print_message "DigitalOcean Spaces Setup Instructions:"
        echo "1. Create a Space:"
        echo "   - Go to DigitalOcean Console: https://cloud.digitalocean.com/spaces"
        echo "   - Click 'Create Space'"
        echo "   - Enter Space name: ${DO_SPACES_NAME}"
        echo "   - Select region: ${DO_SPACES_REGION}"
        echo "   - Choose 'Public' access"
        echo "   - Click 'Create Space'"
        echo ""
        echo "2. Configure CORS:"
        echo "   - Go to your Space"
        echo "   - Click 'Settings'"
        echo "   - Under 'CORS Configurations', click 'Add CORS Configuration'"
        echo "   - Add the following configuration:"
        cat > /tmp/spaces-cors.json << EOL
{
    "AllowedOrigins": [
        "https://${BASE_DOMAIN}",
        "https://www.${BASE_DOMAIN}",
        "https://api.${BASE_DOMAIN}"
    ],
    "AllowedMethods": [
        "GET",
        "HEAD",
        "PUT",
        "POST",
        "DELETE"
    ],
    "AllowedHeaders": [
        "*"
    ],
    "MaxAgeSeconds": 3600
}
EOL
        cat /tmp/spaces-cors.json
        echo ""
        echo "3. Configure CDN (optional):"
        echo "   - Go to your Space"
        echo "   - Click 'Settings'"
        echo "   - Under 'CDN', click 'Enable CDN'"
        echo "   - Choose your CDN endpoint"
        echo ""
        
        # Update environment template with DO settings
        cat >> templates/env/production/api.env.template << EOL

# DigitalOcean Spaces Storage
AWS_ACCESS_KEY_ID=${DO_SPACES_KEY}
AWS_SECRET_ACCESS_KEY=${DO_SPACES_SECRET}
AWS_STORAGE_BUCKET_NAME=${DO_SPACES_NAME}
AWS_S3_REGION_NAME=${DO_SPACES_REGION}
AWS_S3_ENDPOINT_URL=https://${DO_SPACES_REGION}.digitaloceanspaces.com
AWS_S3_CUSTOM_DOMAIN=${DO_SPACES_NAME}.${DO_SPACES_REGION}.digitaloceanspaces.com
AWS_DEFAULT_ACL=public-read
AWS_S3_OBJECT_PARAMETERS={"CacheControl": "max-age=86400"}
AWS_QUERYSTRING_AUTH=False
AWS_S3_FILE_OVERWRITE=False
AWS_S3_VERIFY=True
AWS_S3_SIGNATURE_VERSION=s3v4
EOL
    else
        print_error "Invalid storage provider selected"
        exit 1
    fi
    
    # Add Django storage settings
    cat >> templates/env/production/api.env.template << EOL

# Django Storage Settings
DEFAULT_FILE_STORAGE=storages.backends.s3boto3.S3Boto3Storage
STATICFILES_STORAGE=storages.backends.s3boto3.S3StaticStorage
MEDIAFILES_STORAGE=storages.backends.s3boto3.S3Boto3Storage
AWS_S3_STATIC_LOCATION=static
AWS_S3_MEDIA_LOCATION=media
EOL

    # Create development environment template with local storage
    cat > templates/env/development/api.env.template << EOL
# Django Storage Settings for Development
DEFAULT_FILE_STORAGE=django.core.files.storage.FileSystemStorage
STATICFILES_STORAGE=django.contrib.staticfiles.storage.StaticFilesStorage
MEDIAFILES_STORAGE=django.core.files.storage.FileSystemStorage
EOL

    print_message "Object storage configuration completed"
    print_message "For development, files will be stored locally"
    print_message "For production, files will be stored in ${STORAGE_PROVIDER^^}"
    print_message "Please follow the setup instructions above to configure your storage bucket"
}

# Function to create environment files
create_env_files() {
    print_message "Creating environment files..."
    
    # Get domain information
    DOMAIN=$(get_input "Enter your domain name" "example.com")
    EMAIL=$(get_input "Enter your email for Let's Encrypt" "admin@example.com")
    
    # Create production environment template
    cat > templates/env/production/api.env.template << EOL
# Django settings
DEBUG=False
SECRET_KEY=your-secret-key-here
ALLOWED_HOSTS=${DOMAIN}
CSRF_TRUSTED_ORIGINS=https://${DOMAIN}

# Database settings
DB_NAME=launchkit
DB_USER=launchkit
DB_PASSWORD=your-db-password-here
DB_HOST=localhost
DB_PORT=5432

# Redis settings
REDIS_URL=redis://localhost:6379/0

# RabbitMQ settings
RABBITMQ_DEFAULT_USER=launchkit
RABBITMQ_DEFAULT_PASS=your-rabbitmq-password-here

# Email settings
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-email-password-here
DEFAULT_FROM_EMAIL=your-email@gmail.com
EOL
    
    # Create frontend environment template
    cat > templates/env/production/app.env.template << EOL
# API settings
NEXT_PUBLIC_API_URL=https://${DOMAIN}/api
NEXT_PUBLIC_APP_URL=https://${DOMAIN}

# Authentication
NEXTAUTH_URL=https://${DOMAIN}
NEXTAUTH_SECRET=your-nextauth-secret-here

# Other third-party services
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
NEXT_PUBLIC_GOOGLE_ANALYTICS_ID=your-ga-id
EOL

    # Setup object storage
    setup_object_storage
    
    print_message "Environment templates created. Please update the .env files with your actual values."
}

# Function to setup auto-deployment
setup_auto_deployment() {
    print_message "Setting up auto-deployment..."
    
    # Create auto-deployment script
    cat > /usr/local/bin/check_updates.sh << 'EOL'
#!/bin/bash

# Change to project directory
cd /path/to/launchkit

# Check for updates
git fetch origin

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Check if there are updates
if [ "$(git rev-parse HEAD)" != "$(git rev-parse origin/$CURRENT_BRANCH)" ]; then
    # Pull changes and deploy
    git pull origin $CURRENT_BRANCH
    ./scripts/deploy_production.sh
fi
EOL
    
    # Make script executable
    chmod +x /usr/local/bin/check_updates.sh
    
    # Create systemd service
    cat > /etc/systemd/system/launchkit-updater.service << 'EOL'
[Unit]
Description=LaunchKit Auto Updater
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/check_updates.sh
Restart=always

[Timer]
OnCalendar=*:0/10
Unit=launchkit-updater.service

[Install]
WantedBy=multi-user.target
EOL
    
    # Enable and start the service
    systemctl enable launchkit-updater.timer
    systemctl start launchkit-updater.timer
}

# Main function
main() {
    print_message "Starting server setup..."
    
    # Check if running as root
    check_root
    
    # Install system dependencies
    install_system_dependencies
    
    # Install Docker
    install_docker
    
    # Configure firewall
    configure_firewall
    
    # Setup Nginx
    setup_nginx
    
    # Setup monitoring
    setup_monitoring
    
    # Create environment files
    create_env_files
    
    # Setup auto-deployment
    setup_auto_deployment
    
    print_message "Server setup completed successfully!"
    print_message "Please update the environment files with your actual values."
    print_message "You can find the templates in templates/env/production/"
}

# Run main function
main 