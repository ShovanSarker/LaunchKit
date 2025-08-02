# LaunchKit - Manual Deployment Setup Guide

This guide walks you through setting up LaunchKit using the manual deployment approach with individual service scripts.

## 🚀 Quick Start

### Development Environment

1. **Initial Setup**:
   ```bash
   ./scripts/setup_development.sh
   ```

2. **Start All Services**:
   ```bash
   ./run/development/run_dev_all.sh
   ```

3. **Start Next.js App**:
   ```bash
   cd app && npm run dev
   ```

### Production Environment

1. **Server Setup**:
   ```bash
   ./scripts/setup_server.sh
   ```

2. **Start All Services**:
   ```bash
   ./run/production/run_prod_all.sh
   ```

3. **Post-Deployment Tasks**:
   ```bash
   # Run migrations
   ./run/production/run_backend.sh migrate
   
   # Create superuser
   ./run/production/run_backend.sh createsuperuser
   ```

## 📁 Environment Files

### Development Environment Files

Copy and configure these template files:

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

### Production Environment Files

```bash
# API Environment
cp templates/env/production/api.env.template api/.env
# Edit api/.env with your production values

# Frontend Environment
cp templates/env/production/app.env.template app/.env.local
# Edit app/.env.local with your production values

# Docker Environment
cp templates/env/production/docker.env.template docker/.env
# Edit docker/.env with your production values
```

## 🔧 Individual Service Management

### Development Services

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

### Production Services

```bash
# Backend API
./run/production/run_backend.sh [start|stop|restart|status|logs|migrate|collectstatic|createsuperuser]

# Frontend
./run/production/run_frontend.sh [start|stop|restart|status|logs|build]

# Nginx
./run/production/run_nginx.sh [start|stop|restart|status|logs|test|reload]

# Monitoring
./run/production/run_monitoring.sh [start|stop|restart|status|logs|grafana|prometheus]

# Worker, Scheduler, Redis, RabbitMQ (same as development)
./run/production/run_worker.sh [start|stop|restart|status|logs]
./run/production/run_scheduler.sh [start|stop|restart|status|logs]
./run/production/run_redis.sh [start|stop|restart|status|logs|cli]
./run/production/run_rabbitmq.sh [start|stop|restart|status|logs|ui]
```

## 🌐 Service URLs

### Development
- **API**: http://localhost:8000
- **API Docs**: http://localhost:8000/api/docs/
- **Frontend**: http://localhost:3000
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **RabbitMQ**: localhost:5672
- **RabbitMQ UI**: http://localhost:15672

### Production
- **Main Site**: https://your-domain.com
- **API**: https://api.your-domain.com
- **API Docs**: https://api.your-domain.com/api/docs/
- **Monitoring**: https://monitor.your-domain.com
- **PostgreSQL**: localhost:5432
- **Redis**: localhost:6379
- **RabbitMQ**: localhost:5672
- **RabbitMQ UI**: http://localhost:15672
- **Prometheus**: http://localhost:9090
- **cAdvisor**: http://localhost:8080

## 🔍 Troubleshooting

### Common Issues

1. **Docker not running**:
   ```bash
   # macOS
   open -a Docker
   
   # Linux
   sudo systemctl start docker
   ```

2. **Environment files missing**:
   ```bash
   # Development
   ./scripts/setup_development.sh
   
   # Production
   ./scripts/setup_server.sh
   ```

3. **Port conflicts**:
   ```bash
   # Check what's using the port
   lsof -i :8000
   
   # Kill process if needed
   kill -9 <PID>
   ```

4. **Service dependencies**:
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

### Production Debugging

```bash
# Health check
./run/production/run_prod_all.sh health

# Check specific service
./run/production/run_backend.sh status
./run/production/run_frontend.sh status
./run/production/run_nginx.sh status

# Test Nginx config
./run/production/run_nginx.sh test

# Reload Nginx
./run/production/run_nginx.sh reload
```

## 📋 Environment Variables

### Required Variables

#### API Environment (`api/.env`)
```bash
# Project Settings
PROJECT_NAME=LaunchKit
PROJECT_SLUG=launchkit

# Django Settings
DJANGO_ENV=development  # or production
DEBUG=True  # False for production
DJANGO_SECRET_KEY=your-secret-key
ALLOWED_HOSTS=localhost,127.0.0.1
CSRF_TRUSTED_ORIGINS=http://localhost:3000

# Database
POSTGRES_DB=launchkit
POSTGRES_USER=launchkit
POSTGRES_PASSWORD=your-db-password
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# Redis
REDIS_URL=redis://redis:6379/0

# RabbitMQ
CELERY_BROKER_URL=amqp://launchkit:password@rabbitmq:5672/launchkit

# Email (Production)
EMAIL_BACKEND=sendgrid_backend.SendgridBackend
SENDGRID_API_KEY=your-sendgrid-key
SENDGRID_FROM_EMAIL=your-email@domain.com

# Frontend URL
FRONTEND_URL=http://localhost:3000  # https://your-domain.com for production
```

#### Frontend Environment (`app/.env.local`)
```bash
# Project Information
NEXT_PUBLIC_PROJECT_NAME=LaunchKit
NEXT_PUBLIC_PROJECT_SLUG=launchkit

# API Settings
NEXT_PUBLIC_API_URL=http://localhost:8000  # https://api.your-domain.com for production

# Authentication
NEXTAUTH_URL=http://localhost:3000  # https://your-domain.com for production
NEXTAUTH_SECRET=your-secret-key

# Feature Flags
NEXT_PUBLIC_FEATURE_REGISTRATION_ENABLED=true
NEXT_PUBLIC_FEATURE_SOCIAL_LOGIN_ENABLED=false
```

#### Docker Environment (`docker/.env`)
```bash
# Project Settings
PROJECT_NAME=LaunchKit
PROJECT_SLUG=launchkit

# Domain (Production)
DOMAIN=your-domain.com
EMAIL=admin@your-domain.com

# Database
POSTGRES_DB=launchkit
POSTGRES_USER=launchkit
POSTGRES_PASSWORD=your-db-password

# RabbitMQ
RABBITMQ_DEFAULT_USER=launchkit
RABBITMQ_DEFAULT_PASS=your-rabbitmq-password
RABBITMQ_DEFAULT_VHOST=launchkit

# Monitoring (Production)
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=your-grafana-password
```

## 🚀 Deployment Checklist

### Development
- [ ] Run `./scripts/setup_development.sh`
- [ ] Copy and configure environment files
- [ ] Start services: `./run/development/run_dev_all.sh`
- [ ] Start Next.js: `cd app && npm run dev`
- [ ] Create superuser: `docker exec -it launchkit_api python manage.py createsuperuser`
- [ ] Run migrations: `docker exec -it launchkit_api python manage.py migrate`

### Production
- [ ] Run `./scripts/setup_server.sh`
- [ ] Copy and configure environment files
- [ ] Configure DNS records
- [ ] Set up SSL certificates
- [ ] Start services: `./run/production/run_prod_all.sh`
- [ ] Run migrations: `./run/production/run_backend.sh migrate`
- [ ] Create superuser: `./run/production/run_backend.sh createsuperuser`
- [ ] Collect static files: `./run/production/run_backend.sh collectstatic`
- [ ] Test all endpoints
- [ ] Set up monitoring dashboards

## 📚 Next Steps

After successful deployment:

1. **Explore the API**: Visit the API documentation
2. **Test Authentication**: Create accounts and test login/logout
3. **Monitor Performance**: Check Grafana dashboards
4. **Set up Alerts**: Configure monitoring alerts
5. **Backup Strategy**: Set up database backups
6. **Security Audit**: Review security settings
7. **Performance Tuning**: Optimize based on usage

## 🆘 Getting Help

- **Documentation**: Check `README.md` and `docs/` directory
- **Issues**: Create an issue on GitHub
- **Logs**: Use the log commands to debug issues
- **Health Checks**: Use the health check commands
- **Community**: Join our community discussions 