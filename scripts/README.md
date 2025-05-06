# LaunchKit Development Scripts

This directory contains scripts for managing the LaunchKit development environment.

## Available Scripts

- `init.sh` - Initialize the LaunchKit environment with configuration settings
- `run-dev.sh` - Start/stop the development environment with essential services
- `deploy.sh` - Deploy all services for staging/production
- `make-migrations.sh` - Generate database migrations for Django apps
- `run-migrations.sh` - Apply database migrations and create admin user
- `fix-settings.sh` - Fix Django settings for CELERY_RESULT_BACKEND
- `fix-profiles.sh` - Fix missing profiles for existing users

## Development Workflow

1. **Initial Setup**:
   ```bash
   ./scripts/init.sh
   ```

2. **Start Development Environment**:
   ```bash
   ./scripts/run-dev.sh
   ```

3. **Generate and Apply Migrations**:
   ```bash
   ./scripts/make-migrations.sh
   ./scripts/run-migrations.sh
   ```

4. **Stop Development Environment**:
   ```bash
   ./scripts/run-dev.sh down
   ```

5. **View Service Logs**:
   ```bash
   ./scripts/run-dev.sh logs [service_name]
   ```

6. **Check Running Services**:
   ```bash
   ./scripts/run-dev.sh ps
   ```

7. **Fix User Profiles (if login fails)**:
   ```bash
   ./scripts/fix-profiles.sh
   ```

## Development Services

The development environment includes these essential services:

- PostgreSQL database
- Redis cache
- RabbitMQ message broker
- Django API (running at http://localhost:8000)
- Celery worker
- Celery scheduler (beat)

For the full application with nginx and frontend, use the `deploy.sh` script instead. 