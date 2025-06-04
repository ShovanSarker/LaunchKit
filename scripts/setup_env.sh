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

# Main function
main() {
    print_message "Setting up environment files..."
    
    # Get domain information
    DOMAIN=$(get_input "Enter your domain name" "example.com")
    EMAIL=$(get_input "Enter your email for Let's Encrypt" "admin@example.com")
    
    # Generate secrets
    DJANGO_SECRET_KEY=$(generate_random_string)
    NEXTAUTH_SECRET=$(generate_random_string)
    
    # Get database credentials
    DB_PASSWORD=$(get_input "Enter database password" "$(generate_random_string)")
    RABBITMQ_PASSWORD=$(get_input "Enter RabbitMQ password" "$(generate_random_string)")
    
    # Get email settings
    EMAIL_USER=$(get_input "Enter email address" "admin@${DOMAIN}")
    EMAIL_PASSWORD=$(get_input "Enter email password" "")
    
    # Get AWS credentials
    AWS_ACCESS_KEY=$(get_input "Enter AWS Access Key ID" "")
    AWS_SECRET_KEY=$(get_input "Enter AWS Secret Access Key" "")
    AWS_BUCKET_NAME=$(get_input "Enter S3 Bucket Name" "${DOMAIN}-static")
    AWS_REGION=$(get_input "Enter AWS Region" "us-east-1")
    
    # Create .env file for API
    cat > .env << EOL
# Django settings
DEBUG=False
SECRET_KEY=${DJANGO_SECRET_KEY}
ALLOWED_HOSTS=${DOMAIN}
CSRF_TRUSTED_ORIGINS=https://${DOMAIN}

# Database settings
DB_NAME=launchkit
DB_USER=launchkit
DB_PASSWORD=${DB_PASSWORD}
DB_HOST=localhost
DB_PORT=5432

# Redis settings
REDIS_URL=redis://localhost:6379/0

# RabbitMQ settings
RABBITMQ_DEFAULT_USER=launchkit
RABBITMQ_DEFAULT_PASS=${RABBITMQ_PASSWORD}

# Email settings
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=${EMAIL_USER}
EMAIL_HOST_PASSWORD=${EMAIL_PASSWORD}
DEFAULT_FROM_EMAIL=${EMAIL_USER}

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
    
    print_message "Environment files created successfully!"
    print_message "Please review the .env files and update any missing values."
    print_message "You can now run ./scripts/deploy_production.sh"
}

# Run main function
main 