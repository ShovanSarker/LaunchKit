#!/bin/bash

# =============================================================================
# LaunchKit Production Teardown Script
# =============================================================================
# Safely removes the production stack with optional database and media backups.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${PROJECT_ROOT}/config"
ENV_DIR="${PROJECT_ROOT}/env"
BACKUP_DIR="${PROJECT_ROOT}/backup"

# Function to print messages
print_message() {
    echo -e "${BLUE}[Teardown]${NC} $1"
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

# Function to get compose project name from bootstrap state
get_compose_project_name() {
    local state_file="${CONFIG_DIR}/.bootstrap_state.json"
    local env_file="${ENV_DIR}/.env.prod"
    
    # Try to get from bootstrap state first
    if [ -f "$state_file" ] && command -v jq >/dev/null 2>&1; then
        local project_slug=$(jq -r '.project_slug' "$state_file" 2>/dev/null)
        if [ "$project_slug" != "null" ] && [ -n "$project_slug" ]; then
            echo "${project_slug}-prod"
            return 0
        fi
    fi
    
    # Fallback to environment file
    if [ -f "$env_file" ]; then
        local compose_name=$(grep "^COMPOSE_PROJECT_NAME=" "$env_file" | cut -d'=' -f2)
        if [ -n "$compose_name" ]; then
            echo "$compose_name"
            return 0
        fi
    fi
    
    # Final fallback
    echo "launchkit-prod"
}

# Function to check if production stack is running
check_stack_running() {
    local project_name=$(get_compose_project_name)
    
    if ! docker compose -p "$project_name" ps --format json | grep -q "Up"; then
        print_warning "Production stack is not running"
        return 1
    fi
    
    return 0
}

# Function to create database backup
create_database_backup() {
    local project_name=$(get_compose_project_name)
    local env_file="${ENV_DIR}/.env.prod"
    
    # Get database credentials from environment file
    local db_user=$(grep "^POSTGRES_USER=" "$env_file" | cut -d'=' -f2)
    local db_name=$(grep "^POSTGRES_DB=" "$env_file" | cut -d'=' -f2)
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="${BACKUP_DIR}/db_backup_${timestamp}.dump"
    
    print_message "Creating database backup..."
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Create database backup
    if docker compose -p "$project_name" exec -T db pg_dump -U "$db_user" -d "$db_name" -Fc > "$backup_file"; then
        print_success "Database backup created: $backup_file"
        echo "$backup_file"
    else
        print_error "Failed to create database backup"
        return 1
    fi
}

# Function to create media backup
create_media_backup() {
    local project_name=$(get_compose_project_name)
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="${BACKUP_DIR}/media_backup_${timestamp}.tar.gz"
    
    print_message "Creating media backup..."
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Create media backup
    if docker compose -p "$project_name" exec -T api tar -czf - /app/media > "$backup_file"; then
        print_success "Media backup created: $backup_file"
        echo "$backup_file"
    else
        print_warning "Failed to create media backup (media directory may not exist)"
        return 1
    fi
}

# Function to create environment backup
create_env_backup() {
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="${BACKUP_DIR}/env_backup_${timestamp}.tar.gz"
    
    print_message "Creating environment backup..."
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Create environment backup
    if tar -czf "$backup_file" -C "$PROJECT_ROOT" env/ config/ infra/; then
        print_success "Environment backup created: $backup_file"
        echo "$backup_file"
    else
        print_error "Failed to create environment backup"
        return 1
    fi
}

# Function to offer backups
offer_backups() {
    local db_backup=""
    local media_backup=""
    local env_backup=""
    
    echo
    print_message "Backup Options"
    print_message "=============="
    echo
    
    # Check if stack is running
    if ! check_stack_running; then
        print_warning "Cannot create database/media backups - stack is not running"
        read -p "Continue with environment backup only? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
        
        # Create environment backup only
        env_backup=$(create_env_backup)
        echo "$env_backup"
        return 0
    fi
    
    # Offer database backup
    read -p "Create database backup? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        if db_backup=$(create_database_backup); then
            echo "$db_backup"
        fi
    fi
    
    # Offer media backup
    read -p "Create media backup? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        if media_backup=$(create_media_backup); then
            echo "$media_backup"
        fi
    fi
    
    # Offer environment backup
    read -p "Create environment backup? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        if env_backup=$(create_env_backup); then
            echo "$env_backup"
        fi
    fi
    
    # Return all backup files
    echo "$db_backup"
    echo "$media_backup"
    echo "$env_backup"
}

# Function to stop and remove production stack
stop_production_stack() {
    local project_name=$(get_compose_project_name)
    
    print_message "Stopping production stack..."
    
    # Stop the stack
    if docker compose -p "$project_name" down --remove-orphans; then
        print_success "Production stack stopped and removed"
    else
        print_error "Failed to stop production stack"
        return 1
    fi
}

# Function to remove volumes (optional)
remove_volumes() {
    local project_name=$(get_compose_project_name)
    
    read -p "Remove Docker volumes? This will permanently delete all data! (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Removing Docker volumes..."
        
        # List volumes to be removed
        local volumes=$(docker volume ls -q | grep "^${project_name}_")
        if [ -n "$volumes" ]; then
            echo "The following volumes will be removed:"
            echo "$volumes" | sed 's/^/  - /'
            echo
            
            read -p "Are you absolutely sure? This action cannot be undone! (yes/NO): " -r
            if [[ $REPLY == "yes" ]]; then
                echo "$volumes" | xargs -r docker volume rm
                print_success "Docker volumes removed"
            else
                print_message "Volumes preserved"
            fi
        else
            print_message "No volumes found to remove"
        fi
    else
        print_message "Volumes preserved"
    fi
}

# Function to print backup information
print_backup_info() {
    local backups=("$@")
    
    if [ ${#backups[@]} -gt 0 ]; then
        echo
        print_success "Backups created successfully!"
        echo
        print_message "Backup files:"
        for backup in "${backups[@]}"; do
            if [ -n "$backup" ]; then
                echo "  - $backup"
            fi
        done
        echo
        print_message "Backup location: $BACKUP_DIR"
        echo
        print_message "To restore:"
        echo "  Database: pg_restore -h <host> -U <user> -d <db> <backup_file>"
        echo "  Media:    tar -xzf <backup_file> -C /destination/"
        echo "  Env:      tar -xzf <backup_file> -C /destination/"
    fi
}

# Function to handle script arguments
handle_arguments() {
    case "${1:-}" in
        "--no-backup")
            print_warning "Skipping backup creation"
            return 0
            ;;
        "--prune-volumes")
            print_warning "Will remove volumes after teardown"
            return 0
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [options]"
            echo
            echo "Options:"
            echo "  --no-backup      Skip backup creation"
            echo "  --prune-volumes  Remove Docker volumes after teardown"
            echo "  help             Show this help message"
            exit 0
            ;;
        "")
            # No arguments, continue with normal teardown
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Main function
main() {
    print_message "LaunchKit Production Teardown"
    print_message "============================="
    
    # Handle command line arguments
    local skip_backup=false
    local prune_volumes=false
    
    for arg in "$@"; do
        case "$arg" in
            "--no-backup")
                skip_backup=true
                ;;
            "--prune-volumes")
                prune_volumes=true
                ;;
        esac
    done
    
    # Check if we're in the right directory
    if [ ! -f "${PROJECT_ROOT}/README.md" ]; then
        print_error "Please run this script from the LaunchKit project root"
        exit 1
    fi
    
    # Check if production environment exists
    if [ ! -f "${ENV_DIR}/.env.prod" ]; then
        print_error "Production environment not found. Run ./scripts/bootstrap.sh first."
        exit 1
    fi
    
    # Confirm teardown
    echo
    print_warning "This will stop and remove the production stack."
    print_warning "Make sure you have backups if needed."
    echo
    
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "Teardown cancelled"
        exit 0
    fi
    
    # Create backups (unless skipped)
    local backups=()
    if [ "$skip_backup" = false ]; then
        print_message "Creating backups..."
        mapfile -t backups < <(offer_backups)
    fi
    
    # Stop production stack
    stop_production_stack
    
    # Remove volumes if requested
    if [ "$prune_volumes" = true ]; then
        remove_volumes
    fi
    
    # Print backup information
    print_backup_info "${backups[@]}"
    
    # Print summary
    echo
    print_success "Production teardown completed!"
    echo
    print_message "Summary:"
    echo "  - Production stack stopped and removed"
    if [ "$prune_volumes" = true ]; then
        echo "  - Docker volumes removed"
    else
        echo "  - Docker volumes preserved"
    fi
    if [ "$skip_backup" = false ]; then
        echo "  - Backups created in: $BACKUP_DIR"
    else
        echo "  - Backups skipped"
    fi
    echo
    print_message "To restart production:"
    echo "  ./scripts/run_prod.sh"
    echo
}

# Run main function
main "$@"
