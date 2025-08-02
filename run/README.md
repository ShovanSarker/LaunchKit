# LaunchKit - Manual Run Scripts

This directory contains manual run scripts for individual services and complete environments.

## Directory Structure

```
run/
├── development/
│   ├── run_backend.sh      # Backend API service
│   ├── run_worker.sh       # Celery worker service
│   ├── run_scheduler.sh    # Celery scheduler service
│   ├── run_redis.sh        # Redis service
│   ├── run_rabbitmq.sh     # RabbitMQ service
│   └── run_dev_all.sh      # All development services
└── production/
    ├── run_backend.sh      # Backend API service
    ├── run_worker.sh       # Celery worker service
    ├── run_scheduler.sh    # Celery scheduler service
    ├── run_redis.sh        # Redis service
    ├── run_rabbitmq.sh     # RabbitMQ service
    ├── run_frontend.sh     # Next.js frontend service
    ├── run_nginx.sh        # Nginx reverse proxy
    ├── run_monitoring.sh   # Monitoring stack (Prometheus + Grafana)
    └── run_prod_all.sh     # All production services
```

## Quick Start

### Development Environment

1. **Setup Environment** (first time only):
   ```bash
   ./scripts/setup_development.sh
   ```

2. **Start All Development Services**:
   ```bash
   ./run/development/run_dev_all.sh
   ```

3. **Start Individual Services**:
   ```bash
   # Start backend API
   ./run/development/run_backend.sh
   
   # Start Celery worker
   ./run/development/run_worker.sh
   
   # Start Redis
   ./run/development/run_redis.sh
   
   # Start RabbitMQ
   ./run/development/run_rabbitmq.sh
   ```

### Production Environment

1. **Setup Environment** (first time only):
   ```bash
   ./scripts/setup_server.sh
   ```

2. **Start All Production Services**:
   ```bash
   ./run/production/run_prod_all.sh
   ```

## Service Commands

Each service script supports the following commands:

- `start` - Start the service (default)
- `stop` - Stop the service
- `restart` - Restart the service
- `status` - Show service status
- `logs` - Show service logs
- `help` - Show help information

### Examples

```bash
# Start backend with logs
./run/development/run_backend.sh start

# Stop worker
./run/development/run_worker.sh stop

# Restart Redis
./run/development/run_redis.sh restart

# Show RabbitMQ status
./run/development/run_rabbitmq.sh status

# Show scheduler logs
./run/development/run_scheduler.sh logs
```

## Development Services

### Backend API
- **Port**: 8000
- **URL**: http://localhost:8000
- **Docs**: http://localhost:8000/api/docs/
- **Dependencies**: PostgreSQL, Redis, RabbitMQ

### Celery Worker
- **Purpose**: Process background tasks
- **Dependencies**: Redis, RabbitMQ
- **Logs**: Shows task processing information

### Celery Scheduler
- **Purpose**: Manage periodic tasks
- **Dependencies**: Redis, RabbitMQ
- **Logs**: Shows scheduled task execution

### Redis
- **Port**: 6379
- **Purpose**: Cache and session storage
- **CLI Access**: `./run/development/run_redis.sh cli`

### RabbitMQ
- **Port**: 5672 (AMQP), 15672 (Management UI)
- **Purpose**: Message broker for Celery
- **UI**: http://localhost:15672
- **UI Access**: `./run/development/run_rabbitmq.sh ui`

## Production Services

### Frontend (Next.js)
- **Port**: 3000
- **URL**: https://your-domain.com
- **Purpose**: React/Next.js application

### Nginx
- **Port**: 80 (HTTP), 443 (HTTPS)
- **Purpose**: Reverse proxy and load balancer
- **Features**: SSL termination, rate limiting, caching

### Monitoring Stack
- **Prometheus**: Metrics collection
- **Grafana**: Metrics visualization
- **cAdvisor**: Container metrics
- **Node Exporter**: System metrics

## Environment Files

Before running services, ensure you have the proper environment files:

### Development
- `api/.env` - Backend environment variables
- `app/.env.local` - Frontend environment variables
- `docker/.env` - Docker environment variables

### Production
- `api/.env` - Backend environment variables
- `app/.env.local` - Frontend environment variables
- `docker/.env` - Docker environment variables

## Troubleshooting

### Common Issues

1. **Docker not running**:
   ```bash
   # Start Docker Desktop or Docker daemon
   sudo systemctl start docker  # Linux
   ```

2. **Environment files missing**:
   ```bash
   # Run setup script
   ./scripts/setup_development.sh
   ```

3. **Port conflicts**:
   ```bash
   # Check what's using the port
   lsof -i :8000
   ```

4. **Service dependencies**:
   ```bash
   # Start dependencies first
   ./run/development/run_redis.sh
   ./run/development/run_rabbitmq.sh
   ./run/development/run_backend.sh
   ```

### Debugging

1. **Check service status**:
   ```bash
   ./run/development/run_backend.sh status
   ```

2. **View service logs**:
   ```bash
   ./run/development/run_backend.sh logs
   ```

3. **Check Docker containers**:
   ```bash
   docker ps
   docker logs <container_name>
   ```

## Next Steps

After starting the services:

1. **Start Next.js development server**:
   ```bash
   cd app && npm run dev
   ```

2. **Access the application**:
   - Frontend: http://localhost:3000
   - API: http://localhost:8000
   - API Docs: http://localhost:8000/api/docs/

3. **Create superuser** (first time):
   ```bash
   docker exec -it launchkit_api python manage.py createsuperuser
   ```

4. **Run migrations**:
   ```bash
   docker exec -it launchkit_api python manage.py migrate
   ```

## Environment Variables

All environment variables are documented in the template files:

- `templates/env/development/api.env.template`
- `templates/env/development/app.env.template`
- `templates/env/development/docker.env.template`

Copy these templates to the appropriate locations and update the values marked with `#TODO`. 