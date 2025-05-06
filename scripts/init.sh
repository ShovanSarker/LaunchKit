#!/bin/bash

set -e

# Exit codes
SUCCESS=0
ENV_EXISTS=1
MISSING_DEPS=2
USER_ABORT=3

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_DIR="${PROJECT_ROOT}/docker"
TEMPLATES_DIR="${PROJECT_ROOT}/templates"

# Parse command line arguments
FORCE=false
NON_INTERACTIVE=false

for arg in "$@"; do
  case $arg in
    --force)
      FORCE=true
      shift
      ;;
    --non-interactive)
      NON_INTERACTIVE=true
      shift
      ;;
    *)
      # Unknown option
      ;;
  esac
done

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print styled messages
print_message() {
  echo -e "${BLUE}[LaunchKit]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Function to apply template
apply_template() {
  template_file="$1"
  output_file="$2"
  
  if [ ! -f "$template_file" ]; then
    print_error "Template file not found: $template_file"
    exit $MISSING_DEPS
  fi
  
  # Create output directory if it doesn't exist
  output_dir=$(dirname "$output_file")
  mkdir -p "$output_dir"
  
  # Copy template to output
  cp "$template_file" "$output_file"
  
  # Replace variables in the output file
  # Environment
  sed -i.bak "s|%%PROJECT_SLUG%%|${PROJECT_SLUG}|g" "$output_file"
  sed -i.bak "s|%%DJANGO_ENV%%|${DJANGO_ENV}|g" "$output_file"
  sed -i.bak "s|%%DEBUG%%|${DEBUG}|g" "$output_file"
  sed -i.bak "s|%%ENABLE_MONITORING%%|${ENABLE_MONITORING}|g" "$output_file"
  sed -i.bak "s|%%NODE_ENV%%|${NODE_ENV}|g" "$output_file"
  
  # Credentials
  sed -i.bak "s|%%SECRET_KEY%%|${SECRET_KEY}|g" "$output_file"
  sed -i.bak "s|%%POSTGRES_PASSWORD%%|${POSTGRES_PASSWORD}|g" "$output_file"
  sed -i.bak "s|%%RABBITMQ_PASSWORD%%|${RABBITMQ_PASSWORD}|g" "$output_file"
  sed -i.bak "s|%%POSTGRES_DB%%|${POSTGRES_DB}|g" "$output_file"
  sed -i.bak "s|%%POSTGRES_USER%%|${POSTGRES_USER}|g" "$output_file"
  
  # URLs and domains
  sed -i.bak "s|%%DOMAIN_NAME%%|${DOMAIN_NAME}|g" "$output_file"
  sed -i.bak "s|%%LE_EMAIL%%|${LE_EMAIL}|g" "$output_file"
  
  # Optional services
  sed -i.bak "s|%%SENDGRID_API_KEY%%|${SENDGRID_API_KEY}|g" "$output_file"
  sed -i.bak "s|%%AWS_ACCESS_KEY_ID%%|${AWS_ACCESS_KEY_ID}|g" "$output_file"
  sed -i.bak "s|%%AWS_SECRET_ACCESS_KEY%%|${AWS_SECRET_ACCESS_KEY}|g" "$output_file"
  sed -i.bak "s|%%AWS_S3_BUCKET%%|${AWS_S3_BUCKET}|g" "$output_file"
  sed -i.bak "s|%%SENTRY_DSN%%|${SENTRY_DSN}|g" "$output_file"
  
  # Redis and Celery
  sed -i.bak "s|%%REDIS_URL%%|${REDIS_URL}|g" "$output_file"
  sed -i.bak "s|%%CELERY_BROKER_URL%%|${CELERY_BROKER_URL}|g" "$output_file"
  
  # Remove backup file
  rm -f "${output_file}.bak"
  
  print_success "Created: $output_file"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  print_error "Docker is not installed. Please install Docker and try again."
  exit $MISSING_DEPS
fi

# Check if Docker Compose is installed
if ! docker compose version &> /dev/null; then
  print_error "Docker Compose is not installed. Please install Docker Compose and try again."
  exit $MISSING_DEPS
fi

# Check for existing environment files if not forced
if [ "$FORCE" = "false" ] && [ -f "${PROJECT_ROOT}/.env" ]; then
  print_error "Environment file already exists. Use --force to overwrite."
  exit $ENV_EXISTS
fi

# Get project information
print_message "LaunchKit Initialization"
print_message "======================="
echo

if [ "$NON_INTERACTIVE" = "false" ]; then
  # Project slug
  read -p "Enter project slug (lowercase, no spaces): " PROJECT_SLUG
  PROJECT_SLUG=${PROJECT_SLUG:-launchkit}
  
  # Environment type
  print_message "Choose environment type:"
  echo "1) Development (local)"
  echo "2) Live (production/staging)"
  read -p "Enter your choice [1-2]: " env_choice
  
  case $env_choice in
    1)
      ENV_TYPE="development"
      ;;
    2)
      ENV_TYPE="live"
      
      # For live, ask if it's production or staging
      print_message "Choose deployment environment:"
      echo "1) Production"
      echo "2) Staging"
      read -p "Enter your choice [1-2]: " deploy_choice
      
      case $deploy_choice in
        1)
          DJANGO_ENV="production"
          ;;
        2)
          DJANGO_ENV="staging"
          ;;
        *)
          print_error "Invalid choice. Defaulting to staging."
          DJANGO_ENV="staging"
          ;;
      esac
      ;;
    *)
      print_error "Invalid choice. Defaulting to development."
      ENV_TYPE="development"
      ;;
  esac
else
  # Non-interactive mode - use environment variables or defaults
  PROJECT_SLUG=${PROJECT_SLUG:-launchkit}
  ENV_TYPE=${ENV_TYPE:-development}
  DJANGO_ENV=${DJANGO_ENV:-development}
fi

# Set configuration based on environment type
if [ "$ENV_TYPE" = "development" ]; then
  DJANGO_ENV="development"
  DEBUG="True"
  ENABLE_MONITORING="false"
  NODE_ENV="development"
  
  # Development defaults
  POSTGRES_DB="${PROJECT_SLUG}"
  POSTGRES_USER="${PROJECT_SLUG}"
  REDIS_URL="redis://redis:6379/0"
else
  # Live environment (production or staging)
  DEBUG="False"
  ENABLE_MONITORING="true"
  NODE_ENV="production"
  
  # Live requires domain configuration
  if [ "$NON_INTERACTIVE" = "false" ]; then
    read -p "Enter primary domain name (e.g., example.com): " DOMAIN_NAME
    read -p "Enter email for Let's Encrypt certificate (e.g., admin@example.com): " LE_EMAIL
    
    # AWS S3 configuration for backups and media storage
    read -p "Enter AWS S3 bucket name: " AWS_S3_BUCKET
    read -p "Enter AWS access key ID: " AWS_ACCESS_KEY_ID
    read -s -p "Enter AWS secret access key: " AWS_SECRET_ACCESS_KEY
    echo
    
    # Sendgrid for email
    read -s -p "Enter SendGrid API key: " SENDGRID_API_KEY
    echo
    
    # Sentry for error tracking
    read -p "Enter Sentry DSN (optional): " SENTRY_DSN
  fi
  
  # Set default domain subdomains
  API_DOMAIN="api.${DOMAIN_NAME}"
  WWW_DOMAIN="www.${DOMAIN_NAME}"
  MONITOR_DOMAIN="monitor.${DOMAIN_NAME}"
  
  # Live environment
  POSTGRES_DB="${PROJECT_SLUG}"
  POSTGRES_USER="${PROJECT_SLUG}"
  REDIS_URL="redis://redis:6379/0"
fi

# Generate secure credentials
SECRET_KEY=$(openssl rand -base64 32 | tr -d '\n')
POSTGRES_PASSWORD=$(openssl rand -base64 16 | tr -d '\n')
RABBITMQ_PASSWORD=$(openssl rand -base64 16 | tr -d '\n')

# Create broker URL with credentials
CELERY_BROKER_URL="amqp://${POSTGRES_USER}:${RABBITMQ_PASSWORD}@rabbitmq:5672//"
CELERY_RESULT_BACKEND="${REDIS_URL}"

# Create environment files from templates
print_message "Creating environment files..."

# Create Docker environment file
if [ "$FORCE" = "true" ] || [ ! -f "${PROJECT_ROOT}/.env" ]; then
  apply_template "${TEMPLATES_DIR}/env/docker.env.template" "${PROJECT_ROOT}/.env"
else
  print_warning ".env file already exists. Skipping..."
fi

# Create Docker Compose override file based on environment
print_message "Creating Docker Compose configuration..."

if [ "$ENV_TYPE" = "development" ]; then
  # Development override file
  cat > "${DOCKER_DIR}/docker-compose.override.yml" << EOL
version: '3'
services:
  postgres:
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
  
  redis:
    ports:
      - "6379:6379"
  
  rabbitmq:
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      - RABBITMQ_DEFAULT_USER=${POSTGRES_USER}
      - RABBITMQ_DEFAULT_PASS=${RABBITMQ_PASSWORD}
  
  api:
    build:
      context: ..
      dockerfile: docker/api/Dockerfile
      args:
        - DJANGO_ENV=development
    volumes:
      - ../api:/app
      - media:/app/media
      - static:/app/static
    env_file:
      - ../.env
    ports:
      - "8000:8000"
    command: ["python", "manage.py", "runserver", "0.0.0.0:8000"]
  
  worker:
    build:
      context: ..
      dockerfile: docker/worker/Dockerfile
    volumes:
      - ../api:/app
      - media:/app/media
    env_file:
      - ../.env
  
  scheduler:
    build:
      context: ..
      dockerfile: docker/scheduler/Dockerfile
    volumes:
      - ../api:/app
    env_file:
      - ../.env

volumes:
  pgdata:
  media:
  static:
EOL

  # Create a dev-specific compose file that explicitly lists only the services we want
  cat > "${DOCKER_DIR}/docker-compose.dev.yml" << EOL
version: '3'
services:
  postgres:
  redis:
  rabbitmq:
  api:
  worker:
  scheduler:
EOL
  
  print_message "Development environment: Created configuration for essential services only."
  print_message "To include additional services like nginx or monitoring, use the standard docker-compose commands."
  
else
  # Create Live environment override
  cat > "${DOCKER_DIR}/docker-compose.override.yml" << EOL
version: '3'
services:
  postgres:
    environment:
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    restart: unless-stopped
  
  redis:
    command: redis-server --appendonly yes
    volumes:
      - redisdata:/data
    restart: unless-stopped
  
  rabbitmq:
    environment:
      - RABBITMQ_DEFAULT_USER=${POSTGRES_USER}
      - RABBITMQ_DEFAULT_PASS=${RABBITMQ_PASSWORD}
    volumes:
      - rabbitmqdata:/var/lib/rabbitmq
    restart: unless-stopped
  
  api:
    build:
      context: ..
      dockerfile: docker/api/Dockerfile
      args:
        - DJANGO_ENV=${DJANGO_ENV}
    volumes:
      - media:/app/media
      - static:/app/static
    env_file:
      - ../.env
    restart: unless-stopped
  
  worker:
    build:
      context: ..
      dockerfile: docker/worker/Dockerfile
    volumes:
      - media:/app/media
    env_file:
      - ../.env
    restart: unless-stopped
  
  scheduler:
    build:
      context: ..
      dockerfile: docker/scheduler/Dockerfile
    env_file:
      - ../.env
    restart: unless-stopped
  
  app:
    build:
      context: ..
      dockerfile: docker/app/Dockerfile
    env_file:
      - ../.env
    restart: unless-stopped
  
  nginx:
    build:
      context: docker/nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - static:/static
      - media:/media
      - certs:/etc/letsencrypt
    environment:
      - DOMAIN_NAME=${DOMAIN_NAME}
      - API_DOMAIN=${API_DOMAIN}
      - WWW_DOMAIN=${WWW_DOMAIN}
      - LE_EMAIL=${LE_EMAIL}
    restart: unless-stopped
  
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus:/etc/prometheus
      - prometheus-data:/prometheus
    restart: unless-stopped
  
  grafana:
    image: grafana/grafana:latest
    volumes:
      - grafana-data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_SECURITY_ADMIN_USER=admin
    restart: unless-stopped
  
  loki:
    image: grafana/loki:latest
    volumes:
      - loki-data:/loki
    restart: unless-stopped

volumes:
  pgdata:
  redisdata:
  rabbitmqdata:
  media:
  static:
  certs:
  prometheus-data:
  grafana-data:
  loki-data:
EOL

  # For live, create specific API and APP env files
  if [ "$FORCE" = "true" ] || [ ! -f "${PROJECT_ROOT}/api/.env" ]; then
    apply_template "${TEMPLATES_DIR}/env/api.env.template" "${PROJECT_ROOT}/api/.env"
  else
    print_warning "api/.env file already exists. Skipping..."
  fi
  
  if [ "$FORCE" = "true" ] || [ ! -f "${PROJECT_ROOT}/app/.env" ]; then
    apply_template "${TEMPLATES_DIR}/env/app.env.template" "${PROJECT_ROOT}/app/.env"
  else
    print_warning "app/.env file already exists. Skipping..."
  fi
  
  # Create systemd service for live environment
  if [ "$DJANGO_ENV" = "production" ]; then
    print_message "Creating systemd services for automatic updates and backups..."
    
    # Create backup script
    cat > "${PROJECT_ROOT}/scripts/backup.sh" << 'EOL'
#!/bin/bash
set -e

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${PROJECT_ROOT}/backups"

# Load environment variables
source "${PROJECT_ROOT}/.env"

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Backup PostgreSQL database
echo "Backing up PostgreSQL database..."
docker compose exec -T postgres pg_dump -U "${POSTGRES_USER}" "${POSTGRES_DB}" | gzip > "${BACKUP_DIR}/${POSTGRES_DB}_${TIMESTAMP}.sql.gz"

# Backup media files to S3
echo "Backing up media files to S3..."
docker compose exec -T api aws s3 sync /app/media s3://${AWS_S3_BUCKET}/backups/media_${TIMESTAMP}/

echo "Backup completed: ${TIMESTAMP}"
EOL
    chmod +x "${PROJECT_ROOT}/scripts/backup.sh"
    
    # Create systemd timer and service for backups
    # Note: This would normally be installed by the user manually
    cat > "${PROJECT_ROOT}/scripts/install-services.sh" << 'EOL'
#!/bin/bash
set -e

# Project directory
PROJECT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# Create systemd service for backups
cat > /tmp/launchkit-backup.service << EOF
[Unit]
Description=LaunchKit Database Backup
After=network.target

[Service]
Type=oneshot
WorkingDirectory=${PROJECT_DIR}
ExecStart=${PROJECT_DIR}/scripts/backup.sh
User=root

[Install]
WantedBy=multi-user.target
EOF

# Create systemd timer for backups
cat > /tmp/launchkit-backup.timer << EOF
[Unit]
Description=Run LaunchKit backup daily at 3am

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Move files to systemd directory
sudo mv /tmp/launchkit-backup.service /etc/systemd/system/
sudo mv /tmp/launchkit-backup.timer /etc/systemd/system/

# Enable and start timer
sudo systemctl daemon-reload
sudo systemctl enable launchkit-backup.timer
sudo systemctl start launchkit-backup.timer

echo "Systemd services installed successfully."
EOL
    chmod +x "${PROJECT_ROOT}/scripts/install-services.sh"
    
    print_message "Created systemd service installation script: scripts/install-services.sh"
    print_message "Run as root to install systemd services for automated backups."
  fi
fi

# Create RabbitMQ definitions file if it doesn't exist
RABBITMQ_CONFIG_DIR="${DOCKER_DIR}/rabbitmq"
if [ ! -d "$RABBITMQ_CONFIG_DIR" ]; then
  mkdir -p "$RABBITMQ_CONFIG_DIR"
fi

cat > "${RABBITMQ_CONFIG_DIR}/definitions.json" << EOL
{
  "users": [
    {
      "name": "${POSTGRES_USER}",
      "password": "${RABBITMQ_PASSWORD}",
      "tags": "administrator"
    }
  ],
  "vhosts": [
    {
      "name": "/"
    }
  ],
  "permissions": [
    {
      "user": "${POSTGRES_USER}",
      "vhost": "/",
      "configure": ".*",
      "write": ".*",
      "read": ".*"
    }
  ]
}
EOL

# Now create the run-dev.sh script for local development
if [ "$ENV_TYPE" = "development" ]; then
  cat > "${PROJECT_ROOT}/scripts/run-dev.sh" << 'EOL'
#!/bin/bash
set -e

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_DIR="${PROJECT_ROOT}/docker"

# Color codes for terminal output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Print message
echo -e "${BLUE}[LaunchKit]${NC} Starting development environment..."

# Start development services
docker compose -f "${DOCKER_DIR}/docker-compose.yml" -f "${DOCKER_DIR}/docker-compose.override.yml" up -d

# Success message
echo -e "${GREEN}[SUCCESS]${NC} Development environment is running."
echo
echo "Available services:"
echo "- API: http://localhost:8000"
echo "- PostgreSQL: localhost:5432"
echo "- Redis: localhost:6379"
echo "- RabbitMQ: http://localhost:15672 (admin panel)"
echo
echo "To stop all services:"
echo "  docker compose -f \"${DOCKER_DIR}/docker-compose.yml\" -f \"${DOCKER_DIR}/docker-compose.override.yml\" down"
EOL
  chmod +x "${PROJECT_ROOT}/scripts/run-dev.sh"
  print_success "Created development script: scripts/run-dev.sh"
fi

# Create deploy.sh script for live environments
cat > "${PROJECT_ROOT}/scripts/deploy.sh" << 'EOL'
#!/bin/bash

set -e

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKER_DIR="${PROJECT_ROOT}/docker"

# Parse command line arguments
SKIP_PULL=false

for arg in "$@"; do
  case $arg in
    --skip-pull)
      SKIP_PULL=true
      shift
      ;;
    *)
      # Unknown option
      ;;
  esac
done

# Load environment variables
if [ -f "${PROJECT_ROOT}/.env" ]; then
  source "${PROJECT_ROOT}/.env"
fi

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print styled messages
print_message() {
  echo -e "${BLUE}[LaunchKit Deploy]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if the environment file exists
if [ ! -f "${PROJECT_ROOT}/.env" ]; then
  print_error "Environment file not found. Please run ./scripts/init.sh first."
  exit 1
fi

# For live environments, check DJANGO_ENV
if [ -n "$DJANGO_ENV" ] && [ "$DJANGO_ENV" != "development" ]; then
  print_message "Deploying to ${DJANGO_ENV} environment..."
elif [ "$DJANGO_ENV" == "development" ]; then
  print_message "Deploying to development environment..."
else
  print_error "DJANGO_ENV not set or invalid. Please run ./scripts/init.sh first."
  exit 1
fi

print_message "Starting deployment..."

# 1. Pull latest images (if not skipped)
if [ "$SKIP_PULL" = "false" ]; then
  print_message "Pulling latest Docker images..."
  docker compose -f "${DOCKER_DIR}/docker-compose.yml" -f "${DOCKER_DIR}/docker-compose.override.yml" pull
fi

# 2. Start core infrastructure services first
print_message "Starting infrastructure services (PostgreSQL, Redis, RabbitMQ)..."
docker compose -f "${DOCKER_DIR}/docker-compose.yml" -f "${DOCKER_DIR}/docker-compose.override.yml" up -d postgres redis rabbitmq

# Wait for services to be healthy
print_message "Waiting for infrastructure services to be healthy..."
sleep 10

# 3. Start API service 
print_message "Starting API service..."
docker compose -f "${DOCKER_DIR}/docker-compose.yml" -f "${DOCKER_DIR}/docker-compose.override.yml" up -d api

# 4. Run migrations
print_message "Running database migrations..."
docker compose -f "${DOCKER_DIR}/docker-compose.yml" -f "${DOCKER_DIR}/docker-compose.override.yml" exec -T api python manage.py migrate --noinput

# 5. Collect static files
print_message "Collecting static files..."
docker compose -f "${DOCKER_DIR}/docker-compose.yml" -f "${DOCKER_DIR}/docker-compose.override.yml" exec -T api python manage.py collectstatic --noinput

# 6. Start worker and scheduler (only after migrations are complete)
print_message "Starting Celery worker and scheduler..."
docker compose -f "${DOCKER_DIR}/docker-compose.yml" -f "${DOCKER_DIR}/docker-compose.override.yml" up -d worker scheduler

# 7. Start remaining services (app, nginx, monitoring)
print_message "Starting remaining services..."
docker compose -f "${DOCKER_DIR}/docker-compose.yml" -f "${DOCKER_DIR}/docker-compose.override.yml" up -d --remove-orphans

print_success "Deployment completed successfully!"
print_message "Your LaunchKit application is now running."

# Display information based on environment
if [ "$DJANGO_ENV" == "development" ]; then
  print_message "Access your application at: http://localhost:8000"
  print_message "API is available at: http://localhost:8000/api"
  print_message "Django admin interface: http://localhost:8000/admin/"
else
  # For staging/production
  print_message "Access your application at: https://www.${DOMAIN_NAME}"
  print_message "API is available at: https://api.${DOMAIN_NAME}"
  print_message "Monitoring is available at: https://monitor.${DOMAIN_NAME}"
fi
EOL
chmod +x "${PROJECT_ROOT}/scripts/deploy.sh"

# Final instructions
print_success "LaunchKit configuration has been successfully created!"
echo
print_message "To deploy your application, run:"
echo "  ./scripts/deploy.sh"
echo
if [ "$ENV_TYPE" = "development" ]; then
  print_message "For local development, run:"
  echo "  ./scripts/run-dev.sh"
else
  print_message "For ${DJANGO_ENV} environment, your app will be available at:"
  echo "  - Frontend: https://www.${DOMAIN_NAME}"
  echo "  - API: https://api.${DOMAIN_NAME}"
  echo "  - Monitoring: https://monitor.${DOMAIN_NAME}"
fi 