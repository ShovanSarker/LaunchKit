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

# Function to generate random string
generate_random_string() {
    openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32
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
        python3-venv \
        apache2-utils  # Added for htpasswd
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

# Function to setup AWS storage
setup_aws_storage() {
    print_message "Setting up AWS S3 storage..."
    
    AWS_ACCESS_KEY=$(get_input "Enter AWS Access Key ID" "")
    AWS_SECRET_KEY=$(get_input "Enter AWS Secret Access Key" "")
    AWS_BUCKET_NAME=$(get_input "Enter S3 Bucket Name" "${DOMAIN}-static")
    AWS_REGION=$(get_input "Enter AWS Region" "us-east-1")
    
    # Add AWS settings to environment file
    cat >> .env << EOL

# AWS S3 Storage
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_KEY}
AWS_STORAGE_BUCKET_NAME=${AWS_BUCKET_NAME}
AWS_S3_REGION_NAME=${AWS_REGION}
AWS_S3_CUSTOM_DOMAIN=s3.${AWS_REGION}.amazonaws.com
AWS_DEFAULT_ACL=public-read
AWS_S3_OBJECT_PARAMETERS='{"CacheControl": "max-age=86400"}'
AWS_QUERYSTRING_AUTH=False
AWS_S3_FILE_OVERWRITE=False
AWS_S3_VERIFY=True
AWS_S3_SIGNATURE_VERSION=s3v4
EOL
}

# Function to setup DO storage
setup_do_storage() {
    print_message "Setting up DigitalOcean Spaces storage..."
    
    DO_SPACES_KEY=$(get_input "Enter DO Spaces Key" "")
    DO_SPACES_SECRET=$(get_input "Enter DO Spaces Secret" "")
    DO_SPACES_NAME=$(get_input "Enter DO Spaces Name" "${DOMAIN}-static")
    DO_SPACES_REGION=$(get_input "Enter DO Spaces Region" "nyc3")
    
    # Add DO settings to environment file
    cat >> .env << EOL

# DigitalOcean Spaces Storage
AWS_ACCESS_KEY_ID=${DO_SPACES_KEY}
AWS_SECRET_ACCESS_KEY=${DO_SPACES_SECRET}
AWS_STORAGE_BUCKET_NAME=${DO_SPACES_NAME}
AWS_S3_REGION_NAME=${DO_SPACES_REGION}
AWS_S3_ENDPOINT_URL=https://${DO_SPACES_REGION}.digitaloceanspaces.com
AWS_S3_CUSTOM_DOMAIN=${DO_SPACES_NAME}.${DO_SPACES_REGION}.digitaloceanspaces.com
AWS_DEFAULT_ACL=public-read
AWS_S3_OBJECT_PARAMETERS='{"CacheControl": "max-age=86400"}'
AWS_QUERYSTRING_AUTH=False
AWS_S3_FILE_OVERWRITE=False
AWS_S3_VERIFY=True
AWS_S3_SIGNATURE_VERSION=s3v4
EOL
}

# Function to setup Nginx
setup_nginx() {
    print_message "Setting up Nginx..."
    
    # Create required directories
    mkdir -p nginx/conf.d nginx/ssl
    
    # Create rate limiting configuration
    cat > nginx/conf.d/rate-limit.conf << EOL
# Rate limiting zones
limit_req_zone \$binary_remote_addr zone=api_limit:10m rate=10r/s;
EOL
    
    # Create main application Nginx configuration
    cat > nginx/conf.d/default.conf << EOL
# Main frontend server
server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Frontend
    location / {
        proxy_pass http://frontend:3000;
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
    server_name api.${DOMAIN};

    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'none'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # CORS headers
    add_header 'Access-Control-Allow-Origin' 'https://${DOMAIN}' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization' always;
    add_header 'Access-Control-Expose-Headers' 'Content-Length,Content-Range' always;

    # Rate limiting
    limit_req zone=api_limit burst=20 nodelay;

    # API endpoints
    location / {
        proxy_pass http://api:8000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Handle OPTIONS method for CORS
        if (\$request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' 'https://${DOMAIN}' always;
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
    server_name monitor.${DOMAIN};

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
        proxy_pass http://prometheus:9090;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Grafana
    location / {
        proxy_pass http://grafana:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL
    
    # Create basic auth for monitoring
    print_message "Creating monitoring access credentials..."
    MONITOR_USER=$(get_input "Enter monitoring username" "admin")
    MONITOR_PASS=$(get_input "Enter monitoring password" "monitor123")
    htpasswd -bc nginx/.htpasswd "$MONITOR_USER" "$MONITOR_PASS"
    
    print_message "Nginx configuration created successfully"
    print_message "Frontend will be available at: https://${DOMAIN}"
    print_message "API will be available at: https://api.${DOMAIN}"
    print_message "Monitoring will be available at: https://monitor.${DOMAIN}"
}

# Function to setup monitoring
setup_monitoring() {
    print_message "Setting up monitoring..."
    
    # Create Prometheus directory
    mkdir -p prometheus
    
    # Create Prometheus configuration
    cat > prometheus/prometheus.yml << EOL
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'launchkit'
    static_configs:
      - targets: 
        - 'api:8000'  # Django API
        - 'frontend:3000'  # Next.js Frontend
        - 'postgres:5432'  # PostgreSQL
        - 'redis:6379'  # Redis
        - 'rabbitmq:5672'  # RabbitMQ
        - 'rabbitmq:15672' # RabbitMQ Management
    metrics_path: '/metrics'
    scheme: 'http'

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
EOL
    
    print_message "Monitoring setup completed"
    print_message "Prometheus will be available at: http://localhost:9090"
    print_message "Grafana will be available at: http://localhost:3000"
    print_message "cAdvisor metrics will be available at: http://localhost:8080"
}

# Function to setup auto-deployment
setup_auto_deployment() {
    print_message "Setting up auto-deployment..."
    
    # Get project directory
    PROJECT_DIR=$(pwd)
    
    # Create auto-deployment script
    cat > /usr/local/bin/check_updates.sh << EOL
#!/bin/bash

# Change to project directory
cd ${PROJECT_DIR}

# Check for updates
git fetch origin

# Get current branch
CURRENT_BRANCH=\$(git rev-parse --abbrev-ref HEAD)

# Check if there are updates
if [ "\$(git rev-parse HEAD)" != "\$(git rev-parse origin/\$CURRENT_BRANCH)" ]; then
    # Pull changes and deploy
    git pull origin \$CURRENT_BRANCH
    cd ${PROJECT_DIR} && ./scripts/deploy_production.sh
fi
EOL
    
    # Make script executable
    chmod +x /usr/local/bin/check_updates.sh
    
    # Create systemd service
    cat > /etc/systemd/system/launchkit-updater.service << EOL
[Unit]
Description=LaunchKit Auto Updater
After=network.target

[Service]
Type=oneshot
User=root
WorkingDirectory=${PROJECT_DIR}
ExecStart=/usr/local/bin/check_updates.sh
EOL
    
    # Create systemd timer
    cat > /etc/systemd/system/launchkit-updater.timer << EOL
[Unit]
Description=LaunchKit Auto Update Timer

[Timer]
OnCalendar=*:0/10
Unit=launchkit-updater.service

[Install]
WantedBy=multi-user.target
EOL
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable and start the timer
    systemctl enable launchkit-updater.timer
    systemctl start launchkit-updater.timer
    
    print_message "Auto-deployment setup completed"
    print_message "The system will check for updates every 10 minutes"
}

# Function to setup backup service
setup_backup_service() {
    print_message "Setting up backup service..."
    
    # Create backup directory
    mkdir -p /backup
    
    # Create backup script
    cat > /usr/local/bin/backup.sh << EOL
#!/bin/bash

# Change to project directory
cd ${PROJECT_DIR}

# Backup timestamp
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup"

# Database backup
docker compose -f docker/docker-compose.prod.yml exec -T postgres pg_dump -U \${POSTGRES_USER} > \${BACKUP_DIR}/db_\${TIMESTAMP}.sql

# Compress backup
gzip \${BACKUP_DIR}/db_\${TIMESTAMP}.sql

# Keep only last 7 days of backups
find \${BACKUP_DIR} -name "db_*.sql.gz" -mtime +7 -delete
EOL
    
    # Make backup script executable
    chmod +x /usr/local/bin/backup.sh
    
    # Create systemd service
    cat > /etc/systemd/system/backup.service << EOL
[Unit]
Description=LaunchKit Backup Service
After=network.target

[Service]
Type=oneshot
User=root
WorkingDirectory=${PROJECT_DIR}
ExecStart=/usr/local/bin/backup.sh

[Install]
WantedBy=multi-user.target
EOL
    
    # Create systemd timer
    cat > /etc/systemd/system/backup.timer << EOL
[Unit]
Description=LaunchKit Backup Timer

[Timer]
OnCalendar=*-*-* 02:00:00
Unit=backup.service

[Install]
WantedBy=multi-user.target
EOL
    
    # Enable and start the timer
    systemctl daemon-reload
    systemctl enable backup.timer
    systemctl start backup.timer
    
    print_message "Backup service setup completed"
    print_message "Backups will run daily at 2:00 AM"
}

# Function to setup additional security
setup_security() {
    print_message "Setting up additional security measures..."
    
    # Install fail2ban
    apt-get install -y fail2ban
    
    # Configure fail2ban
    cat > /etc/fail2ban/jail.local << 'EOL'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 3
bantime = 3600
EOL
    
    # Start fail2ban
    systemctl enable fail2ban
    systemctl start fail2ban
    
    # Set up automatic security updates
    apt-get install -y unattended-upgrades
    
    cat > /etc/apt/apt.conf.d/20auto-upgrades << 'EOL'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOL
    
    # Configure automatic updates
    cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOL'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESM:${distro_codename}";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::DevRelease "auto";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOL
    
    print_message "Additional security measures setup completed"
}

# Function to create docker-compose file
create_docker_compose() {
    print_message "Creating Docker Compose file..."
    
    # Create docker directory if it doesn't exist
    mkdir -p docker
    
    # Create docker-compose file
    cat > docker/docker-compose.prod.yml << EOL
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

  # Frontend service
  frontend:
    build:
      context: ../app
      dockerfile: Dockerfile
    container_name: ${PROJECT_SLUG}_frontend
    volumes:
      - ../app:/app
    env_file:
      - ../app/.env
    depends_on:
      - api
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
      - frontend
    restart: unless-stopped

  # Prometheus for monitoring
  prometheus:
    image: prom/prometheus:latest
    container_name: ${PROJECT_SLUG}_prometheus
    volumes:
      - ../prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    ports:
      - "9090:9090"
    restart: unless-stopped

  # Grafana for visualization
  grafana:
    image: grafana/grafana:latest
    container_name: ${PROJECT_SLUG}_grafana
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
    ports:
      - "3000:3000"
    depends_on:
      - prometheus
    restart: unless-stopped

  # cAdvisor for container metrics
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: ${PROJECT_SLUG}_cadvisor
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    ports:
      - "8080:8080"
    restart: unless-stopped

  # Node Exporter for system metrics
  node-exporter:
    image: prom/node-exporter:latest
    container_name: ${PROJECT_SLUG}_node_exporter
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - "9100:9100"
    restart: unless-stopped

volumes:
  pgdata:
  redisdata:
  prometheus_data:
  grafana_data:

networks:
  default:
    name: ${PROJECT_SLUG}_network
EOL

    print_message "Docker Compose file created successfully"
}

# Function to setup database
setup_database() {
    print_message "Setting up database..."
    
    # Store the current directory
    CURRENT_DIR=$(pwd)
    
    # Check if Docker is running and start it if needed
    if ! systemctl is-active --quiet docker; then
        print_message "Docker is not running. Starting Docker..."
        systemctl start docker
        sleep 5  # Wait for Docker to start
    fi
    
    # Create docker directory and docker-compose file
    create_docker_compose
    
    # Create required directories
    mkdir -p nginx/conf.d nginx/ssl
    
    # Load environment variables
    if [ -f "${CURRENT_DIR}/.env" ]; then
        set -a  # automatically export all variables
        source "${CURRENT_DIR}/.env"
        set +a
    else
        print_error "Environment file .env not found in ${CURRENT_DIR}"
        exit 1
    fi
    
    # Print environment variables for debugging (without sensitive data)
    print_message "Checking environment variables..."
    print_message "POSTGRES_DB: ${POSTGRES_DB}"
    print_message "POSTGRES_USER: ${POSTGRES_USER}"
    print_message "POSTGRES_HOST: ${POSTGRES_HOST}"
    
    # Start database container with environment variables
    print_message "Starting database container..."
    cd "${CURRENT_DIR}/docker" && \
    POSTGRES_DB=${POSTGRES_DB} \
    POSTGRES_USER=${POSTGRES_USER} \
    POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
    RABBITMQ_DEFAULT_USER=${RABBITMQ_DEFAULT_USER} \
    RABBITMQ_DEFAULT_PASS=${RABBITMQ_DEFAULT_PASS} \
    RABBITMQ_DEFAULT_VHOST=${RABBITMQ_DEFAULT_VHOST} \
    docker compose -f docker-compose.prod.yml --env-file "${CURRENT_DIR}/.env" up -d postgres
    
    # Wait for database to be ready
    print_message "Waiting for database to be ready..."
    sleep 10
    
    # Check container status
    print_message "Checking container status..."
    docker ps | grep ${PROJECT_SLUG}_postgres
    
    # Check container logs
    print_message "Checking container logs..."
    docker logs ${PROJECT_SLUG}_postgres
    
    # Try to connect to database with explicit password
    print_message "Attempting database connection..."
    if docker compose -f docker-compose.prod.yml --env-file "${CURRENT_DIR}/.env" exec -T postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "\l" > /dev/null 2>&1; then
        print_message "Database connection successful"
    else
        print_error "Database connection failed"
        print_message "Attempting to connect with explicit password..."
        PGPASSWORD=${POSTGRES_PASSWORD} docker compose -f docker-compose.prod.yml --env-file "${CURRENT_DIR}/.env" exec -T postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "\l"
        
        print_message "Please check if:"
        print_message "1. Docker is running"
        print_message "2. Environment variables are set correctly"
        print_message "3. Port 5432 is available"
        print_message "4. Database container is healthy"
        exit 1
    fi
    
    cd "${CURRENT_DIR}"
}

# Main function
main() {
    print_message "Starting server setup..."
    
    # Check if running as root
    check_root
    
    # Get project directory
    PROJECT_DIR=$(pwd)
    
    # Get domain information
    DOMAIN=$(get_input "Enter your domain name" "example.com")
    EMAIL=$(get_input "Enter your email for Let's Encrypt" "admin@example.com")
    PROJECT_SLUG=$(get_input "Enter project slug (e.g., launchkit)" "launchkit")
    
    # Ask about SSL configuration
    CONFIGURE_SSL=$(get_input "Do you want to configure SSL with Let's Encrypt? (yes/no)" "yes")
    if [ "$CONFIGURE_SSL" = "yes" ]; then
        print_message "SSL will be configured with Let's Encrypt"
        SSL_ENABLED=true
    else
        print_message "SSL configuration will be skipped"
        SSL_ENABLED=false
    fi
    
    # Generate secrets
    DJANGO_SECRET_KEY=$(generate_random_string)
    NEXTAUTH_SECRET=$(generate_random_string)
    
    # Get database credentials
    POSTGRES_PASSWORD=$(get_input "Enter database password" "$(generate_random_string)")
    RABBITMQ_PASSWORD=$(get_input "Enter RabbitMQ password" "$(generate_random_string)")
    
    # Get SendGrid settings
    print_message "Setting up SendGrid email configuration..."
    SENDGRID_API_KEY=$(get_input "Enter SendGrid API Key" "")
    SENDGRID_FROM_EMAIL=$(get_input "Enter SendGrid verified sender email" "noreply@${DOMAIN}")
    SENDGRID_FROM_NAME=$(get_input "Enter SendGrid sender name" "${PROJECT_SLUG}")
    
    # Create .env file for API
    cat > .env << EOL
# Django settings
DEBUG=False
SECRET_KEY=${DJANGO_SECRET_KEY}
ALLOWED_HOSTS=${DOMAIN}
CSRF_TRUSTED_ORIGINS=https://${DOMAIN}

# Domain and Email settings
DOMAIN=${DOMAIN}
EMAIL=${EMAIL}

# Database settings
POSTGRES_DB=${PROJECT_SLUG}
POSTGRES_USER=${PROJECT_SLUG}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# Redis settings
REDIS_URL=redis://redis:6379/0

# RabbitMQ settings
RABBITMQ_DEFAULT_USER=${PROJECT_SLUG}
RABBITMQ_DEFAULT_PASS=${RABBITMQ_PASSWORD}
RABBITMQ_DEFAULT_VHOST=/

# SendGrid Email settings
EMAIL_BACKEND=sendgrid_backend.SendgridBackend
SENDGRID_API_KEY=${SENDGRID_API_KEY}
SENDGRID_FROM_EMAIL=${SENDGRID_FROM_EMAIL}
SENDGRID_FROM_NAME=${SENDGRID_FROM_NAME}
DEFAULT_FROM_EMAIL=${SENDGRID_FROM_EMAIL}
EOL
    
    # Get storage provider
    STORAGE_PROVIDER=$(get_input "Choose storage provider (do/aws)" "do")
    
    if [ "$STORAGE_PROVIDER" = "aws" ]; then
        setup_aws_storage
    elif [ "$STORAGE_PROVIDER" = "do" ]; then
        setup_do_storage
    else
        print_error "Invalid storage provider selected"
        exit 1
    fi
    
    # Add common storage settings
    cat >> .env << EOL

# Django Storage Settings
DEFAULT_FILE_STORAGE=storages.backends.s3boto3.S3Boto3Storage
STATICFILES_STORAGE=storages.backends.s3boto3.S3StaticStorage
MEDIAFILES_STORAGE=storages.backends.s3boto3.S3Boto3Storage
AWS_S3_STATIC_LOCATION=static
AWS_S3_MEDIA_LOCATION=media
EOL
    
    # Create .env file for frontend
    cat > app/.env << EOL
# API settings
NEXT_PUBLIC_API_URL=https://${DOMAIN}/api
NEXT_PUBLIC_APP_URL=https://${DOMAIN}

# Authentication
NEXTAUTH_URL=https://${DOMAIN}
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}

# Other third-party services
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
NEXT_PUBLIC_GOOGLE_ANALYTICS_ID=your-ga-id
EOL
    
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
    
    # Setup backup service
    setup_backup_service
    
    # Setup additional security
    setup_security
    
    # Setup auto-deployment
    setup_auto_deployment
    
    # Setup database
    setup_database
    
    # Run deployment script
    cd ${PROJECT_DIR} && ./scripts/deploy_production.sh
    
    print_message "Server setup completed successfully!"
    print_message "Please review the .env files and update any missing values."
    print_message "Backup service is configured to run daily at 2:00 AM"
    print_message "Security updates are configured to run automatically"
    print_message "Fail2ban is configured to protect against brute force attacks"
}

# Run main function
main 