#!/bin/bash

set -e

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print styled messages
print_message() {
  echo -e "${BLUE}[Setup]${NC} $1"
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

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATES_DIR="${PROJECT_ROOT}/templates"

# Generate random string for secrets
generate_random_string() {
  length=${1:-50}
  LC_ALL=C tr -dc 'a-zA-Z0-9!@%^&*_+=' < /dev/urandom | head -c${length}
}

# Check if a file exists and ask before overwriting
check_file_exists() {
  local file=$1
  if [ -f "$file" ]; then
    print_warning "File already exists: $file"
    print_warning "This script will not overwrite existing environment files."
    return 1
  fi
  return 0
}

# Create file if it doesn't exist or append content if it does
append_or_create_file() {
  local file=$1
  local content=$2
  local should_append=${3:-false}
  
  # Create directory if it doesn't exist
  mkdir -p "$(dirname "$file")"
  
  if [ "$should_append" = true ] && [ -f "$file" ]; then
    # Append content to file
    echo "$content" >> "$file"
    print_success "Updated: $file"
  else
    # Create new file with content
    echo "$content" > "$file"
    print_success "Created: $file"
  fi
}

# Function to get project info
get_project_info() {
  print_message "Enter project information:"
  
  read -p "Enter project name (e.g., MyProject): " PROJECT_NAME
  PROJECT_NAME=${PROJECT_NAME:-"LaunchKit"}
  
  # Convert project name to lowercase for slug
  suggested_slug=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
  read -p "Enter project slug (lowercase, no spaces) [$suggested_slug]: " PROJECT_SLUG
  PROJECT_SLUG=${PROJECT_SLUG:-$suggested_slug}
  
  read -p "Enter project description: " PROJECT_DESCRIPTION
  PROJECT_DESCRIPTION=${PROJECT_DESCRIPTION:-"A full-stack boilerplate for modern web applications"}
  
  # Export variables for Docker and other processes
  export PROJECT_NAME
  export PROJECT_SLUG
  
  # Create or update root .env file with project settings
  cat > "${PROJECT_ROOT}/.env" << EOL
# Project Settings
PROJECT_NAME=${PROJECT_NAME}
PROJECT_SLUG=${PROJECT_SLUG}
EOL
  
  print_message "Project name: ${PROJECT_NAME}"
  print_message "Project slug: ${PROJECT_SLUG}"
  print_message "Project description: ${PROJECT_DESCRIPTION}"
}

# Generate environment variables
generate_env_variables() {
  print_message "Generating environment variables..."
  
  # Generate secret keys and passwords
  SECRET_KEY=$(generate_random_string 50)
  DB_PASSWORD=$(generate_random_string 16)
  RABBITMQ_PASSWORD=$(generate_random_string 16)
}

# Apply template
apply_template() {
  template_file="$1"
  output_file="$2"
  
  if [ ! -f "$template_file" ]; then
    print_error "Template file not found: $template_file"
    exit 1
  fi
  
  # Check if output file exists
  check_file_exists "$output_file" || return 1
  
  # Create output directory if it doesn't exist
  output_dir=$(dirname "$output_file")
  mkdir -p "$output_dir"
  
  # Copy template to output
  cp "$template_file" "$output_file"
  
  # Replace variables in the output file
  sed -i.bak "s|%%PROJECT_NAME%%|${PROJECT_NAME}|g" "$output_file"
  sed -i.bak "s|%%PROJECT_SLUG%%|${PROJECT_SLUG}|g" "$output_file"
  sed -i.bak "s|%%PROJECT_DESCRIPTION%%|${PROJECT_DESCRIPTION}|g" "$output_file"
  sed -i.bak "s|%%SECRET_KEY%%|${SECRET_KEY}|g" "$output_file"
  sed -i.bak "s|%%DB_PASSWORD%%|${DB_PASSWORD}|g" "$output_file"
  sed -i.bak "s|%%RABBITMQ_PASSWORD%%|${RABBITMQ_PASSWORD}|g" "$output_file"
  
  # Remove backup file
  rm -f "${output_file}.bak"
  
  print_success "Created: $output_file"
  return 0
}

# Setup development environment
setup_development() {
  print_message "Setting up development environment..."
  
  # Apply API environment template
  api_env_template="${TEMPLATES_DIR}/env/development/api.env.template"
  api_env_file="${PROJECT_ROOT}/api/.env"
  apply_template "$api_env_template" "$api_env_file"
  
  # Apply Next.js app environment template
  app_env_template="${TEMPLATES_DIR}/env/development/app.env.template"
  app_env_file="${PROJECT_ROOT}/app/.env.local"
  apply_template "$app_env_template" "$app_env_file"
  
  # Create Docker environment file in root
  docker_env_template="${TEMPLATES_DIR}/env/development/docker.env.template"
  docker_env_file="${PROJECT_ROOT}/.env"
  apply_template "$docker_env_template" "$docker_env_file"
  
  # Create Docker environment file in docker directory and ensure it exists
  mkdir -p "${PROJECT_ROOT}/docker"
  docker_dir_env_file="${PROJECT_ROOT}/docker/.env"
  
  # Check if docker/.env exists and if not, create it directly
  if [ ! -f "$docker_dir_env_file" ]; then
    print_message "Creating Docker environment file in docker directory..."
    cat > "$docker_dir_env_file" << EOF
# Docker Environment - Development

# Project Settings
PROJECT_NAME=${PROJECT_NAME}
PROJECT_SLUG=${PROJECT_SLUG}

# Django Settings
DJANGO_SETTINGS_MODULE=project.settings.development
DEBUG=True

# Database
POSTGRES_DB=${PROJECT_SLUG}
POSTGRES_USER=${PROJECT_SLUG}
POSTGRES_PASSWORD=${DB_PASSWORD}

# RabbitMQ
RABBITMQ_DEFAULT_USER=${PROJECT_SLUG}
RABBITMQ_DEFAULT_PASS=${RABBITMQ_PASSWORD}
RABBITMQ_DEFAULT_VHOST=${PROJECT_SLUG}

# Environment
ENVIRONMENT=development
EOF
    print_success "Created: ${docker_dir_env_file}"
  else
    # Make sure we overwrite the existing file with current settings
    cat > "$docker_dir_env_file" << EOF
# Docker Environment - Development

# Project Settings
PROJECT_NAME=${PROJECT_NAME}
PROJECT_SLUG=${PROJECT_SLUG}

# Django Settings
DJANGO_SETTINGS_MODULE=project.settings.development
DEBUG=True

# Database
POSTGRES_DB=${PROJECT_SLUG}
POSTGRES_USER=${PROJECT_SLUG}
POSTGRES_PASSWORD=${DB_PASSWORD}

# RabbitMQ
RABBITMQ_DEFAULT_USER=${PROJECT_SLUG}
RABBITMQ_DEFAULT_PASS=${RABBITMQ_PASSWORD}
RABBITMQ_DEFAULT_VHOST=${PROJECT_SLUG}

# Environment
ENVIRONMENT=development
EOF
    print_success "Updated: ${docker_dir_env_file}"
  fi

  # Export DJANGO_SETTINGS_MODULE for the current shell session
  export DJANGO_SETTINGS_MODULE=project.settings.development
  print_success "Set DJANGO_SETTINGS_MODULE=project.settings.development for current session"
}

# Update requirements files
update_requirements() {
  print_message "Updating requirements files..."
  
  # Create requirements directory if it doesn't exist
  requirements_dir="${PROJECT_ROOT}/api/requirements"
  mkdir -p "$requirements_dir"
  
  # Check base requirements
  base_requirements="${requirements_dir}/base.txt"
  if [ -f "$base_requirements" ]; then
    print_message "Checking for missing base packages..."
    
    # List of packages that should be in base requirements
    packages=(
      "django-filter"
      "djangorestframework-simplejwt"
      "django-cors-headers"
      "dj-database-url"
      "django-axes"
      "django-environ"
      "django-storages"
      "django-redis"
      "drf-spectacular"
      "psycopg2-binary"
      "celery"
      "redis"
    )
    
    # Check for missing packages and add them if needed
    for package in "${packages[@]}"; do
      if ! grep -q "$package" "$base_requirements"; then
        echo "# Added by setup script" >> "$base_requirements"
        echo "$package" >> "$base_requirements"
        print_success "Added $package to base requirements"
      fi
    done
  else
    # Create base requirements file
    cat > "$base_requirements" << EOF
# Django and Django REST Framework
Django==4.2.10
djangorestframework==3.14.0
django-cors-headers==4.3.1
django-filter==23.5
drf-spectacular==0.27.0

# Database
psycopg2-binary==2.9.9
dj-database-url==2.1.0

# Environment & Settings
python-dotenv==1.0.0
django-environ==0.11.2

# Authentication
django-allauth==0.57.0
dj-rest-auth==5.0.1
djangorestframework-simplejwt==5.3.0
django-axes==7.1.0

# Cache & Sessions
django-redis==5.4.0

# Background Tasks
celery==5.3.4
redis==5.0.1
django-celery-beat==2.5.0
django-celery-results==2.5.1

# Production
gunicorn==21.2.0
whitenoise==6.5.0

# Utilities
Pillow==10.1.0
python-slugify==8.0.1
argon2-cffi==23.1.0

# Storage
django-storages==1.14.2
boto3==1.28.53
EOF
    print_success "Created: $base_requirements"
  fi
  
  # Check dev requirements
  dev_requirements="${requirements_dir}/dev.txt"
  if [ -f "$dev_requirements" ]; then
    print_message "Checking for missing dev packages..."
    
    # Check if -r base.txt is at the top
    if ! grep -q "^-r base.txt" "$dev_requirements"; then
      sed -i.bak '1s/^/-r base.txt\n\n/' "$dev_requirements"
      rm -f "${dev_requirements}.bak"
      print_success "Added -r base.txt to dev requirements"
    fi
    
    # List of packages that should be in dev requirements
    packages=(
      "django-debug-toolbar"
      "pytest"
      "pytest-django"
      "black"
      "isort"
      "watchdog"
    )
    
    # Check for missing packages and add them if needed
    for package in "${packages[@]}"; do
      if ! grep -q "$package" "$dev_requirements"; then
        echo "# Added by setup script" >> "$dev_requirements"
        echo "$package" >> "$dev_requirements"
        print_success "Added $package to dev requirements"
      fi
    done
  else
    # Create dev requirements file
    cat > "$dev_requirements" << EOF
-r base.txt

# Development tools
django-debug-toolbar==4.2.0
black==24.2.0
ruff==0.1.15
isort==5.13.2
djlint==1.34.1
pytest==7.4.3
pytest-django==4.7.0
pytest-cov==4.1.0
factory-boy==3.3.0
Faker==22.5.0
ipython==8.16.1
watchdog==3.0.0
EOF
    print_success "Created: $dev_requirements"
  fi
  
  # Check prod requirements
  prod_requirements="${requirements_dir}/prod.txt"
  if [ -f "$prod_requirements" ]; then
    print_message "Checking for missing prod packages..."
    
    # Check if -r base.txt is at the top
    if ! grep -q "^-r base.txt" "$prod_requirements"; then
      sed -i.bak '1s/^/-r base.txt\n\n/' "$prod_requirements"
      rm -f "${prod_requirements}.bak"
      print_success "Added -r base.txt to prod requirements"
    fi
  else
    # Create prod requirements file
    cat > "$prod_requirements" << EOF
-r base.txt

# Production-specific packages
django-storages[s3]==1.14.2
whitenoise==6.6.0
sentry-sdk==1.41.0
django-csp==3.7
EOF
    print_success "Created: $prod_requirements"
  fi
}

# Create docker-compose file
create_docker_compose() {
  print_message "Creating Docker Compose file..."
  
  # Create docker directory if it doesn't exist
  mkdir -p "${PROJECT_ROOT}/docker"
  
  docker_compose_file="${PROJECT_ROOT}/docker/docker-compose.yml"
  
  if check_file_exists "$docker_compose_file"; then
    cat > "$docker_compose_file" << EOF
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
      - DJANGO_SETTINGS_MODULE=project.settings.development
      - DEBUG=True
      - POSTGRES_HOST=postgres
      - POSTGRES_DB=\${POSTGRES_DB}
      - POSTGRES_USER=\${POSTGRES_USER}
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
    depends_on:
      - postgres
      - redis
      - rabbitmq
    ports:
      - "8000:8000"
    command: python manage.py runserver 0.0.0.0:8000

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
      - DJANGO_SETTINGS_MODULE=project.settings.development
      - DEBUG=True
      - POSTGRES_HOST=postgres
      - POSTGRES_DB=\${POSTGRES_DB}
      - POSTGRES_USER=\${POSTGRES_USER}
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
    depends_on:
      - postgres
      - redis
      - rabbitmq
    command: celery -A project worker --loglevel=info

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
      - DJANGO_SETTINGS_MODULE=project.settings.development
      - DEBUG=True
      - POSTGRES_HOST=postgres
      - POSTGRES_DB=\${POSTGRES_DB}
      - POSTGRES_USER=\${POSTGRES_USER}
      - POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}
    depends_on:
      - postgres
      - redis
      - rabbitmq
    command: celery -A project beat --loglevel=info

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

volumes:
  pgdata:
  redisdata:
EOF
    print_success "Created: $docker_compose_file"
  fi
}

# Create entrypoint script
create_entrypoint_script() {
  print_message "Creating Docker entrypoint script..."
  
  entrypoint_script="${PROJECT_ROOT}/api/docker-entrypoint.sh"
  
  if check_file_exists "$entrypoint_script"; then
    cat > "$entrypoint_script" << EOF
#!/bin/bash

set -e

# Function to check if PostgreSQL is available
postgres_ready() {
    # Check if we can connect to PostgreSQL
    PGPASSWORD=\$POSTGRES_PASSWORD psql -h \$POSTGRES_HOST -U \$POSTGRES_USER -d \$POSTGRES_DB -c "SELECT 1" >/dev/null 2>&1
}

# Wait for PostgreSQL to be available
until postgres_ready; do
    echo "PostgreSQL is unavailable - sleeping"
    sleep 1
done

echo "PostgreSQL is up - executing command"

# Apply migrations
if [ "\$1" = "python" ] && [ "\$2" = "manage.py" ] && [ "\$3" = "runserver" ]; then
    echo "Applying migrations..."
    python manage.py migrate --noinput
fi

# Execute the passed command
exec "\$@"
EOF
    chmod +x "$entrypoint_script"
    print_success "Created: $entrypoint_script"
  fi
}

# Create run script
create_run_script() {
  print_message "Creating run script..."
  
  run_script="${PROJECT_ROOT}/scripts/run_dev.sh"
  
  if check_file_exists "$run_script"; then
    cat > "$run_script" << EOF
#!/bin/bash

set -e

# Project root directory
PROJECT_ROOT="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"

# Project information
PROJECT_NAME="${PROJECT_NAME}"
PROJECT_SLUG="${PROJECT_SLUG}"

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "\${BLUE}[${PROJECT_NAME}]${NC} Starting development environment..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo -e "\${RED}[ERROR]${NC} Docker is not running. Please start Docker and try again."
  exit 1
fi

# Start all services
echo -e "\${BLUE}[${PROJECT_NAME}]${NC} Starting all containerized services..."
cd "\${PROJECT_ROOT}/docker" && docker compose up -d

# Check if all containers are running
if [ \$(docker ps --filter "name=${PROJECT_SLUG}" --format '{{.Names}}' | wc -l) -lt 5 ]; then
  echo -e "\${YELLOW}[WARNING]${NC} Not all containers are running. Check logs for errors:"
  echo "  docker logs ${PROJECT_SLUG}_postgres"
  echo "  docker logs ${PROJECT_SLUG}_api"
else
  echo -e "\${GREEN}[SUCCESS]${NC} Development environment is running!"
fi

echo -e "\${BLUE}[INFO]${NC} Available Services:"
echo "  → API:         http://localhost:8000"
echo "  → API Docs:    http://localhost:8000/api/docs/"
echo "  → PostgreSQL:  localhost:5432 (username: ${PROJECT_SLUG}, password: in .env file)"
echo "  → Redis:       localhost:6379"
echo "  → RabbitMQ:    localhost:5672 (admin: http://localhost:15672)"

echo -e "\${BLUE}[INFO]${NC} Container Logs:"
echo "  → API:       docker logs -f ${PROJECT_SLUG}_api"
echo "  → Worker:    docker logs -f ${PROJECT_SLUG}_worker"
echo "  → Scheduler: docker logs -f ${PROJECT_SLUG}_scheduler"
echo "  → Database:  docker logs -f ${PROJECT_SLUG}_postgres"

echo -e "\${BLUE}[INFO]${NC} Development Commands:"
echo "  → Start Next.js App:  cd app && npm run dev"
echo "  → Run Django Shell:   docker exec -it ${PROJECT_SLUG}_api python manage.py shell"
echo "  → Run Migrations:     docker exec -it ${PROJECT_SLUG}_api python manage.py migrate"
echo "  → Create Superuser:   docker exec -it ${PROJECT_SLUG}_api python manage.py createsuperuser"
echo "  → Stop All Services:  cd docker && docker compose down"
EOF
    chmod +x "$run_script"
    print_success "Created: $run_script"
  fi
}

# Show next steps
show_next_steps() {
  print_message "Setup complete for ${PROJECT_NAME}!"
  print_message "Next steps:"
  echo "1. Start all services:"
  echo "   $ ./scripts/run_dev.sh"
  echo ""
  echo "2. Services available after startup:"
  echo "   • API:         http://localhost:8000"
  echo "   • API Docs:    http://localhost:8000/api/docs/"
  echo "   • PostgreSQL:  localhost:5432 (username: ${PROJECT_SLUG}, password in .env file)"
  echo "   • Redis:       localhost:6379"
  echo "   • RabbitMQ:    localhost:5672 (admin UI: http://localhost:15672)"
  echo ""
  echo "3. Development tools:"
  echo "   • Start Next.js app:  cd app && npm run dev"
  echo "   • Run Django Shell:   docker exec -it ${PROJECT_SLUG}_api python manage.py shell"
  echo "   • Create Superuser:   docker exec -it ${PROJECT_SLUG}_api python manage.py createsuperuser"
  echo "   • View API logs:      docker logs -f ${PROJECT_SLUG}_api"
  echo ""
  echo "4. For daily development, you just need to run:"
  echo "   $ ./scripts/run_dev.sh"
  echo "   $ cd app && npm run dev"
}

# Cleanup any existing files that are now in different locations
cleanup_old_files() {
  print_message "Cleaning up old files..."
  
  # Remove docker-compose.yml from root if it exists
  if [ -f "${PROJECT_ROOT}/docker-compose.yml" ]; then
    print_warning "Removing docker-compose.yml from root directory as it's now in the docker folder"
    rm -f "${PROJECT_ROOT}/docker-compose.yml"
  fi
}

# Create Dockerfile for API
create_api_dockerfile() {
  print_message "Creating Dockerfile for API..."
  
  dockerfile="${PROJECT_ROOT}/api/Dockerfile"
  
  if check_file_exists "$dockerfile"; then
    cat > "$dockerfile" << EOF
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Install dependencies
COPY requirements/ /app/requirements/

# Install build dependencies and Python requirements
RUN apt-get update \\
    && apt-get install -y --no-install-recommends gcc python3-dev libpq-dev postgresql-client \\
    && pip install --no-cache-dir -r requirements/dev.txt \\
    && apt-get purge -y --auto-remove gcc python3-dev \\
    && apt-get clean \\
    && rm -rf /var/lib/apt/lists/*

# Copy entrypoint script first
COPY docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

# Copy project files
COPY . /app/

# Expose port
EXPOSE 8000

# Set entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]

# Run command
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
EOF
    print_success "Created: $dockerfile"
  fi
}

# Update API env template
update_api_env_template() {
  print_message "Updating API environment template..."
  
  api_env_template="${TEMPLATES_DIR}/env/development/api.env.template"
  
  if [ -f "$api_env_template" ]; then
    # Check if the file already contains necessary entries
    if ! grep -q "DATABASE_URL" "$api_env_template"; then
      # Create a new template with updated values
      cat > "$api_env_template" << EOF
# API Environment - Development

# Project Information
PROJECT_NAME=%%PROJECT_NAME%%
PROJECT_SLUG=%%PROJECT_SLUG%%

# Django Settings
DJANGO_ENV=development
DEBUG=True
DJANGO_SETTINGS_MODULE=project.settings.development
DJANGO_SECRET_KEY=%%SECRET_KEY%%
ALLOWED_HOSTS=localhost,127.0.0.1,api.localhost
CSRF_TRUSTED_ORIGINS=http://localhost:3000,http://localhost:8000,http://127.0.0.1:3000,http://127.0.0.1:8000

# Database
POSTGRES_DB=%%PROJECT_SLUG%%
POSTGRES_USER=%%PROJECT_SLUG%%
POSTGRES_PASSWORD=%%DB_PASSWORD%%
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# Django Database (used by Django ORM)
DATABASE_URL=postgres://%%PROJECT_SLUG%%:%%DB_PASSWORD%%@postgres:5432/%%PROJECT_SLUG%%

# Redis
REDIS_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0

# RabbitMQ
CELERY_BROKER_URL=amqp://%%PROJECT_SLUG%%:%%RABBITMQ_PASSWORD%%@rabbitmq:5672/%%PROJECT_SLUG%%

# Email (Development)
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
DEFAULT_FROM_EMAIL=noreply@%%PROJECT_SLUG%%.local

# CORS
CORS_ALLOW_ALL_ORIGINS=True

# Frontend URL
FRONTEND_URL=http://localhost:3000

# JWT Settings
JWT_ACCESS_TOKEN_LIFETIME=60
JWT_REFRESH_TOKEN_LIFETIME=1440
EOF
      print_success "Updated: $api_env_template"
    fi
  else
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$api_env_template")"
    
    # Create a new template with the same content as above
    cat > "$api_env_template" << EOF
# API Environment - Development

# Project Information
PROJECT_NAME=%%PROJECT_NAME%%
PROJECT_SLUG=%%PROJECT_SLUG%%

# Django Settings
DJANGO_ENV=development
DEBUG=True
DJANGO_SETTINGS_MODULE=project.settings.development
DJANGO_SECRET_KEY=%%SECRET_KEY%%
ALLOWED_HOSTS=localhost,127.0.0.1,api.localhost
CSRF_TRUSTED_ORIGINS=http://localhost:3000,http://localhost:8000,http://127.0.0.1:3000,http://127.0.0.1:8000

# Database
POSTGRES_DB=%%PROJECT_SLUG%%
POSTGRES_USER=%%PROJECT_SLUG%%
POSTGRES_PASSWORD=%%DB_PASSWORD%%
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# Django Database (used by Django ORM)
DATABASE_URL=postgres://%%PROJECT_SLUG%%:%%DB_PASSWORD%%@postgres:5432/%%PROJECT_SLUG%%

# Redis
REDIS_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0

# RabbitMQ
CELERY_BROKER_URL=amqp://%%PROJECT_SLUG%%:%%RABBITMQ_PASSWORD%%@rabbitmq:5672/%%PROJECT_SLUG%%

# Email (Development)
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
DEFAULT_FROM_EMAIL=noreply@%%PROJECT_SLUG%%.local

# CORS
CORS_ALLOW_ALL_ORIGINS=True

# Frontend URL
FRONTEND_URL=http://localhost:3000

# JWT Settings
JWT_ACCESS_TOKEN_LIFETIME=60
JWT_REFRESH_TOKEN_LIFETIME=1440
EOF
    print_success "Created: $api_env_template"
  fi
}

# Update Docker env template
update_docker_env_template() {
  print_message "Updating Docker environment template..."
  
  docker_env_template="${TEMPLATES_DIR}/env/development/docker.env.template"
  
  if [ -f "$docker_env_template" ]; then
    # Check if the file already contains RabbitMQ entries
    if ! grep -q "RABBITMQ_DEFAULT_USER" "$docker_env_template"; then
      # Create a new template with updated values
      cat > "$docker_env_template" << EOF
# Docker Environment - Development

# Project Settings
PROJECT_NAME=%%PROJECT_NAME%%
PROJECT_SLUG=%%PROJECT_SLUG%%

# Database
POSTGRES_DB=%%PROJECT_SLUG%%
POSTGRES_USER=%%PROJECT_SLUG%%
POSTGRES_PASSWORD=%%DB_PASSWORD%%

# RabbitMQ
RABBITMQ_DEFAULT_USER=%%PROJECT_SLUG%%
RABBITMQ_DEFAULT_PASS=%%RABBITMQ_PASSWORD%%
RABBITMQ_DEFAULT_VHOST=%%PROJECT_SLUG%%

# Environment
ENVIRONMENT=development
EOF
      print_success "Updated: $docker_env_template"
    fi
  else
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$docker_env_template")"
    
    # Create a new template
    cat > "$docker_env_template" << EOF
# Docker Environment - Development

# Project Settings
PROJECT_NAME=%%PROJECT_NAME%%
PROJECT_SLUG=%%PROJECT_SLUG%%

# Database
POSTGRES_DB=%%PROJECT_SLUG%%
POSTGRES_USER=%%PROJECT_SLUG%%
POSTGRES_PASSWORD=%%DB_PASSWORD%%

# RabbitMQ
RABBITMQ_DEFAULT_USER=%%PROJECT_SLUG%%
RABBITMQ_DEFAULT_PASS=%%RABBITMQ_PASSWORD%%
RABBITMQ_DEFAULT_VHOST=%%PROJECT_SLUG%%

# Environment
ENVIRONMENT=development
EOF
    print_success "Created: $docker_env_template"
  fi
}

# Update app env template
update_app_env_template() {
  print_message "Updating Next.js app environment template..."
  
  app_env_template="${TEMPLATES_DIR}/env/development/app.env.template"
  
  if [ -f "$app_env_template" ]; then
    # Check if the file already contains project info
    if ! grep -q "PROJECT_NAME" "$app_env_template"; then
      # Create a new template with updated values
      cat > "$app_env_template" << EOF
# Next.js App Environment - Development

# Project Information
NEXT_PUBLIC_PROJECT_NAME=%%PROJECT_NAME%%
NEXT_PUBLIC_PROJECT_SLUG=%%PROJECT_SLUG%%
NEXT_PUBLIC_PROJECT_DESCRIPTION="A full-stack boilerplate for modern web applications"

# API Settings
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_API_DOCS=http://localhost:8000/api/docs/

# Authentication
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=%%SECRET_KEY%%
NEXT_PUBLIC_JWT_AUTH_HEADER=Authorization
NEXT_PUBLIC_JWT_REFRESH_TOKEN_NAME=refresh_token

# Feature Flags
NEXT_PUBLIC_FEATURE_REGISTRATION_ENABLED=true
EOF
      print_success "Updated: $app_env_template"
    fi
  else
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$app_env_template")"
    
    # Create a new template
    cat > "$app_env_template" << EOF
# Next.js App Environment - Development

# Project Information
NEXT_PUBLIC_PROJECT_NAME=%%PROJECT_NAME%%
NEXT_PUBLIC_PROJECT_SLUG=%%PROJECT_SLUG%%
NEXT_PUBLIC_PROJECT_DESCRIPTION="A full-stack boilerplate for modern web applications"

# API Settings
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_API_DOCS=http://localhost:8000/api/docs/

# Authentication
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=%%SECRET_KEY%%
NEXT_PUBLIC_JWT_AUTH_HEADER=Authorization
NEXT_PUBLIC_JWT_REFRESH_TOKEN_NAME=refresh_token

# Feature Flags
NEXT_PUBLIC_FEATURE_REGISTRATION_ENABLED=true
EOF
    print_success "Created: $app_env_template"
  fi
}

# Main function
main() {
  print_message "Development Environment Setup"
  print_message "============================="
  
  # Get project info
  get_project_info
  
  # Generate environment variables
  generate_env_variables
  
  # Cleanup old files
  cleanup_old_files
  
  # Update templates
  update_api_env_template
  update_app_env_template
  update_docker_env_template
  
  # Setup environment
  setup_development
  
  # Update requirements
  update_requirements
  
  # Create docker-compose file
  create_docker_compose
  
  # Create entrypoint script
  create_entrypoint_script
  
  # Create API Dockerfile
  create_api_dockerfile
  
  # Create run script
  create_run_script
  
  # Show next steps
  show_next_steps
}

# Run the main function
main 