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
  LC_ALL=C tr -dc 'a-zA-Z0-9!@#$%^&*()_+=' < /dev/urandom | head -c${length}
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

# Get project info
get_project_info() {
  print_message "Enter project information:"
  
  read -p "Enter project name (e.g., MyProject): " PROJECT_NAME
  PROJECT_NAME=${PROJECT_NAME:-"LaunchKit"}
  
  # Convert project name to lowercase for slug
  suggested_slug=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
  read -p "Enter project slug (lowercase, no spaces) [$suggested_slug]: " PROJECT_SLUG
  PROJECT_SLUG=${PROJECT_SLUG:-$suggested_slug}
  
  print_message "Project name: ${PROJECT_NAME}"
  print_message "Project slug: ${PROJECT_SLUG}"
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
  
  # Create Docker environment file
  docker_env_template="${TEMPLATES_DIR}/env/development/docker.env.template"
  docker_env_file="${PROJECT_ROOT}/.env"
  apply_template "$docker_env_template" "$docker_env_file"
}

# Create docker-compose file
create_docker_compose() {
  print_message "Creating Docker Compose file..."
  
  docker_compose_file="${PROJECT_ROOT}/docker-compose.yml"
  
  if check_file_exists "$docker_compose_file"; then
    cat > "$docker_compose_file" << EOF
version: '3'

services:
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

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "\${BLUE}[Run]${NC} Starting development environment..."

# Start database services
echo -e "\${BLUE}[Run]${NC} Starting infrastructure services (postgres, redis, rabbitmq)..."
docker compose up -d postgres redis rabbitmq

# Wait for services to be ready
echo -e "\${BLUE}[Run]${NC} Waiting for services to be ready..."
sleep 5

echo -e "\${GREEN}[SUCCESS]${NC} Development environment is running!"
echo -e "\${BLUE}[Run]${NC} To start the API, run: cd api && python manage.py runserver"
echo -e "\${BLUE}[Run]${NC} To start the worker, run: cd api && celery -A project worker --loglevel=info"
echo -e "\${BLUE}[Run]${NC} To start the scheduler, run: cd api && celery -A project beat --loglevel=info"
echo -e "\${BLUE}[Run]${NC} To start the frontend, run: cd app && npm run dev"

echo -e "\${BLUE}[Run]${NC} PostgreSQL is available at: localhost:5432"
echo -e "\${BLUE}[Run]${NC} Redis is available at: localhost:6379"
echo -e "\${BLUE}[Run]${NC} RabbitMQ is available at: localhost:5672 (admin: localhost:15672)"
EOF
    chmod +x "$run_script"
    print_success "Created: $run_script"
  fi
}

# Show next steps
show_next_steps() {
  print_message "Setup complete!"
  print_message "Next steps:"
  echo "1. Start the infrastructure services:"
  echo "   $ ./scripts/run_dev.sh"
  echo ""
  echo "2. Start the API server:"
  echo "   $ cd api && python manage.py runserver"
  echo ""
  echo "3. Start the Celery worker:"
  echo "   $ cd api && celery -A project worker --loglevel=info"
  echo ""
  echo "4. Start the Celery beat scheduler:"
  echo "   $ cd api && celery -A project beat --loglevel=info"
  echo ""
  echo "5. Start the Next.js app:"
  echo "   $ cd app && npm run dev"
}

# Main function
main() {
  print_message "Development Environment Setup"
  print_message "============================="
  
  # Get project info
  get_project_info
  
  # Generate environment variables
  generate_env_variables
  
  # Setup environment
  setup_development
  
  # Create docker-compose file
  create_docker_compose
  
  # Create run script
  create_run_script
  
  # Show next steps
  show_next_steps
}

# Run the main function
main 