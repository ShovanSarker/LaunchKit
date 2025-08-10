# Development Guide

This guide covers setting up and running LaunchKit in a development environment using the manual deployment approach.

## Prerequisites

Before getting started, ensure you have the following installed:

- [Docker](https://www.docker.com/get-started) (v20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2.0+)
- [Node.js](https://nodejs.org/) (v18+)
- [Git](https://git-scm.com/downloads)

## Quick Start

### 1. Initial Setup

Run the development setup script to create environment templates:

```bash
./scripts/setup_development.sh
```

This script will:
- Create environment templates in `templates/env/development/`
- Set up the run scripts directory structure
- Configure project settings

### 2. Configure Environment Files

Copy and configure the environment templates:

```bash
# API Environment
cp templates/env/development/api.env.template api/.env
# Edit api/.env with your values

# Frontend Environment  
cp templates/env/development/app.env.template app/.env.local
# Edit app/.env.local with your values

# Docker Environment
cp templates/env/development/docker.env.template docker/.env
# Edit docker/.env with your values
```

### 3. Start Development Services

Start the backend services using the manual scripts:

```bash
# Start all development services (backend, database, Redis, RabbitMQ)
./run/development/run_dev_all.sh
```

### 4. Start Frontend

Start the Next.js development server:

```bash
cd app && npm run dev
```

### 5. Access Your Application

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Documentation**: http://localhost:8000/api/docs/
- **Admin Interface**: http://localhost:8000/admin

## Manual Service Management

### Individual Service Control

You can start, stop, and manage individual services:

```bash
# Backend API
./run/development/run_backend.sh [start|stop|restart|status|logs]

# Celery Worker
./run/development/run_worker.sh [start|stop|restart|status|logs]

# Celery Scheduler
./run/development/run_scheduler.sh [start|stop|restart|status|logs]

# Redis
./run/development/run_redis.sh [start|stop|restart|status|logs|cli]

# RabbitMQ
./run/development/run_rabbitmq.sh [start|stop|restart|status|logs|ui]
```

### All Services at Once

```bash
# Start all services
./run/development/run_dev_all.sh

# Stop all services
./run/development/run_dev_all.sh stop

# Restart all services
./run/development/run_dev_all.sh restart

# View logs for all services
./run/development/run_dev_all.sh logs
```

## Development Workflow

### Daily Development

1. **Start services**:
   ```bash
   ./run/development/run_dev_all.sh
   ```

2. **Start frontend**:
   ```bash
   cd app && npm run dev
   ```

3. **Make changes** to your code

4. **View logs** if needed:
   ```bash
   ./run/development/run_backend.sh logs
   ```

### Database Operations

```bash
# Run migrations
docker exec -it launchkit_api python manage.py migrate

# Create superuser
docker exec -it launchkit_api python manage.py createsuperuser

# Django shell
docker exec -it launchkit_api python manage.py shell

# Reset database
docker exec -it launchkit_api python manage.py flush
```

### Code Quality

```bash
# Format Python code
cd api && black .
cd api && isort .

# Format JavaScript/TypeScript code
cd app && npm run format

# Run tests
cd api && python manage.py test
cd app && npm test
```

## Environment Configuration

### API Environment (`api/.env`)

Key settings to configure:

```bash
# Project Settings
PROJECT_NAME=YourProjectName
PROJECT_SLUG=yourproject

# Django Settings
DJANGO_ENV=development
DEBUG=True
DJANGO_SECRET_KEY=your-secret-key-here

# Database
POSTGRES_DB=yourproject
POSTGRES_USER=yourproject
POSTGRES_PASSWORD=your-db-password
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# Redis
REDIS_URL=redis://redis:6379/0

# RabbitMQ
CELERY_BROKER_URL=amqp://yourproject:password@rabbitmq:5672/yourproject

# Frontend URL
FRONTEND_URL=http://localhost:3000
```

### Frontend Environment (`app/.env.local`)

Key settings to configure:

```bash
# Project Information
NEXT_PUBLIC_PROJECT_NAME=YourProjectName
NEXT_PUBLIC_PROJECT_SLUG=yourproject

# API Settings
NEXT_PUBLIC_API_URL=http://localhost:8000

# Authentication
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-nextauth-secret

# Feature Flags
NEXT_PUBLIC_FEATURE_REGISTRATION_ENABLED=true
NEXT_PUBLIC_FEATURE_SOCIAL_LOGIN_ENABLED=false
```

### Docker Environment (`docker/.env`)

Key settings to configure:

```bash
# Project Settings
PROJECT_NAME=YourProjectName
PROJECT_SLUG=yourproject

# Database
POSTGRES_DB=yourproject
POSTGRES_USER=yourproject
POSTGRES_PASSWORD=your-db-password

# RabbitMQ
RABBITMQ_DEFAULT_USER=yourproject
RABBITMQ_DEFAULT_PASS=your-rabbitmq-password
RABBITMQ_DEFAULT_VHOST=yourproject
```

## Service URLs

### Development Services

- **API**: http://localhost:8000
- **API Docs**: http://localhost:8000/api/docs/
- **Frontend**: http://localhost:3000
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **RabbitMQ**: localhost:5672
- **RabbitMQ UI**: http://localhost:15672

## Troubleshooting

### Common Issues

1. **Docker not running**:
   ```bash
   # macOS
   open -a Docker
   
   # Linux
   sudo systemctl start docker
   ```

2. **Port conflicts**:
   ```bash
   # Check what's using the port
   lsof -i :8000
   
   # Kill process if needed
   kill -9 <PID>
   ```

3. **Service dependencies**:
   ```bash
   # Start dependencies first
   ./run/development/run_redis.sh
   ./run/development/run_rabbitmq.sh
   ./run/development/run_backend.sh
   ```

### Debugging Commands

```bash
# Check service status
./run/development/run_backend.sh status

# View service logs
./run/development/run_backend.sh logs

# Check Docker containers
docker ps
docker logs <container_name>

# Check Docker Compose
cd docker && docker compose ps
cd docker && docker compose logs -f
```

### Reset Development Environment

If you need to reset your development environment:

```bash
# Stop all services
./run/development/run_dev_all.sh stop

# Remove containers and volumes
cd docker && docker compose down -v

# Rebuild containers
cd docker && docker compose build --no-cache

# Start services again
./run/development/run_dev_all.sh
```

## Next Steps

After setting up your development environment:

1. **Explore the API**: Visit http://localhost:8000/api/docs/
2. **Create a superuser**: `docker exec -it launchkit_api python manage.py createsuperuser`
3. **Run migrations**: `docker exec -it launchkit_api python manage.py migrate`
4. **Test authentication**: Create accounts and test login/logout
5. **Add your features**: Start building your application

## Additional Resources

- [Production Guide](PRODUCTION.md) - Deploy to production
- [Manual Setup Guide](../run/SETUP_GUIDE.md) - Detailed manual deployment guide
- [API Handling Guide](../API_HANDLING_GUIDE.md) - API development guidelines
- [Celery Setup Guide](../celery-setup.md) - Background task configuration 