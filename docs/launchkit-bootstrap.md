# LaunchKit Bootstrap System

This document describes the one-command bootstrap and run system for LaunchKit, providing seamless deployment for both development and production environments.

## Overview

The LaunchKit bootstrap system provides a simple, automated way to deploy the full stack with minimal configuration. It consists of:

- **Bootstrap Script**: Interactive setup for project configuration
- **Run Scripts**: One-command deployment for dev/prod environments
- **Teardown Script**: Safe removal with backup options
- **Docker Compose**: Complete stack definitions for both environments

## Quick Start

### 1. Initial Setup

```bash
# Run the bootstrap script
./scripts/bootstrap.sh
```

The bootstrap script will:
- Prompt for project name and environment (dev/prod)
- Generate secure secrets and passwords
- Create environment files
- Set up authentication for monitoring (production)
- Write bootstrap state for idempotency

### 2. Development Deployment

```bash
# Start development stack
./scripts/run_dev.sh
```

This starts:
- PostgreSQL database
- Redis cache
- RabbitMQ message broker
- Django API with hot reload
- Celery worker and scheduler

### 3. Production Deployment

```bash
# Start production stack
./scripts/run_prod.sh
```

This starts the full production stack including:
- All development services
- Next.js frontend
- Nginx reverse proxy with SSL
- Flower monitoring (protected)
- Optional monitoring tools

## System Requirements

### Operating System
- Ubuntu 22.04+ or macOS 12+
- Windows 10+ with WSL2

### Runtime Dependencies
- Docker Engine 20.10+
- Docker Compose V2

### CLI Dependencies
- bash
- sed (GNU or BSD compatible)
- openssl (or /dev/urandom fallback)
- jq (optional, for enhanced project naming)
- wget
- tar
- pg_dump (for backups)

### Installation Commands

**Ubuntu/Debian:**
```bash
sudo apt-get update && sudo apt-get install -y jq openssl wget tar postgresql-client
```

**macOS:**
```bash
brew install jq coreutils gnu-sed openssl postgresql@16
```

## Project Structure

```
LaunchKit/
├── config/
│   └── .bootstrap_state.json          # Auto-created by bootstrap
├── env/
│   ├── .env.dev.example               # Development template
│   └── .env.prod.example              # Production template
├── infra/
│   ├── nginx/
│   │   └── nginx.conf                 # Nginx configuration
│   └── auth/
│       └── htpasswd                    # Created at bootstrap (prod)
├── scripts/
│   ├── bootstrap.sh                   # Initial setup script
│   ├── run_dev.sh                     # Development runner
│   ├── run_prod.sh                    # Production runner
│   └── teardown_prod.sh               # Safe teardown
├── docker-compose.dev.yml             # Development stack
├── docker-compose.prod.yml            # Production stack
├── api/
│   └── Dockerfile                     # API container
└── app/
    └── Dockerfile                     # Next.js container
```

## Environment Configuration

### Development Environment

The development environment uses simplified configuration with default values suitable for local development:

**Key Variables:**
- `PROJECT_NAME`: Human-readable project name
- `COMPOSE_PROJECT_NAME`: Docker Compose project prefix
- `DJANGO_DEBUG`: Set to 1 for development
- `DJANGO_SECRET_KEY`: Auto-generated secure key
- `DATABASE_URL`: PostgreSQL connection string
- `CELERY_BROKER_URL`: RabbitMQ connection string
- `REDIS_URL`: Redis connection string

### Production Environment

The production environment requires more configuration for security and domain setup:

**Required Variables:**
- `PUBLIC_DOMAIN_API`: API domain (e.g., api.example.com)
- `PUBLIC_DOMAIN_APP`: Frontend domain (e.g., app.example.com)
- `ADMIN_EMAIL`: Email for SSL certificates
- `DJANGO_SECRET_KEY`: Strong random secret
- `POSTGRES_PASSWORD`: Secure database password
- `RABBITMQ_DEFAULT_PASS`: Secure RabbitMQ password

## Scripts Reference

### bootstrap.sh

Interactive setup script that configures the project for either development or production.

**Usage:**
```bash
./scripts/bootstrap.sh
```

**Features:**
- Project name and slug generation
- Environment selection (dev/prod)
- Domain validation for production
- Secure secret generation
- htpasswd creation for Flower monitoring
- Bootstrap state persistence

### run_dev.sh

Launches the complete development stack with hot reload and debugging enabled.

**Usage:**
```bash
./scripts/run_dev.sh [command]
```

**Commands:**
- `(no args)`: Start development stack
- `stop`: Stop development stack
- `restart`: Restart development stack
- `logs [service]`: Show logs
- `status`: Show service status
- `help`: Show help

**Services Started:**
- PostgreSQL (port 5432)
- Redis (port 6379)
- RabbitMQ (ports 5672, 15672)
- Django API (port 8000)
- Celery Worker
- Celery Scheduler

### run_prod.sh

Deploys the complete production stack with monitoring and SSL support.

**Usage:**
```bash
./scripts/run_prod.sh [command]
```

**Commands:**
- `(no args)`: Start production stack
- `stop`: Stop production stack
- `restart`: Restart production stack
- `logs [service]`: Show logs
- `status`: Show service status
- `pull`: Pull latest images
- `help`: Show help

**Services Started:**
- All development services (internal only)
- Next.js frontend (internal)
- Nginx reverse proxy (ports 80, 443)
- Flower monitoring (protected)
- Optional monitoring tools

### teardown_prod.sh

Safely removes the production stack with optional backup creation.

**Usage:**
```bash
./scripts/teardown_prod.sh [options]
```

**Options:**
- `--no-backup`: Skip backup creation
- `--prune-volumes`: Remove Docker volumes
- `help`: Show help

**Backup Options:**
- Database backup (pg_dump)
- Media files backup (tar)
- Environment configuration backup

## Docker Compose Files

### docker-compose.dev.yml

Development stack with:
- **db**: PostgreSQL 16 with health checks
- **redis**: Redis 7 with health checks
- **amqp**: RabbitMQ 3 with management UI
- **api**: Django API with hot reload
- **worker**: Celery worker
- **scheduler**: Celery beat scheduler

**Features:**
- Volume mounts for hot reload
- Exposed ports for debugging
- Health checks for all services
- Development-friendly configuration

### docker-compose.prod.yml

Production stack with:
- All development services (internal)
- **nextjs**: Next.js frontend
- **flower**: Celery monitoring (protected)
- **nginx**: Reverse proxy with SSL
- **uptime-kuma**: Uptime monitoring (optional)
- **dozzle**: Log viewer (optional)

**Features:**
- Internal networking only
- SSL termination at Nginx
- Basic auth for monitoring
- Health checks and restart policies
- Monitoring profiles

## Nginx Configuration

The Nginx configuration provides:

**HTTP to HTTPS Redirect:**
- Automatic redirect from HTTP to HTTPS
- ACME HTTP-01 challenge support for Let's Encrypt

**SSL Configuration:**
- Modern TLS protocols (TLSv1.2, TLSv1.3)
- Strong cipher suites
- HSTS headers
- SSL session optimization

**Routing:**
- API domain → Django backend
- App domain → Next.js frontend
- Static/media file serving
- Flower monitoring (protected)

**Security:**
- Rate limiting
- Security headers
- Basic auth for monitoring
- Request size limits

## Health Checks

All services include health checks:

**Database:**
```bash
pg_isready -U $POSTGRES_USER
```

**Redis:**
```bash
redis-cli ping
```

**RabbitMQ:**
```bash
rabbitmq-diagnostics ping
```

**API:**
```bash
curl -f http://localhost:8000/healthz
```

**Next.js:**
```bash
wget -qO- http://localhost:3000/healthz
```

**Nginx:**
```bash
wget -qO- http://localhost/healthz
```

## Monitoring

### Flower (Celery Monitoring)
- **URL**: `https://api.example.com/flower/`
- **Auth**: Basic authentication
- **Features**: Task monitoring, worker status, queue management

### Uptime Kuma (Optional)
- **URL**: `http://localhost:3001`
- **Features**: HTTP monitoring, uptime tracking, alerts

### Dozzle (Optional)
- **URL**: `http://localhost:9999`
- **Features**: Real-time log viewing, container logs

## SSL Configuration

### Automatic SSL with Let's Encrypt

1. **Configure DNS:**
   ```
   A     api.example.com    → Your server IP
   A     app.example.com    → Your server IP
   ```

2. **Obtain certificates:**
   ```bash
   certbot --nginx -d api.example.com -d app.example.com
   ```

3. **Auto-renewal:**
   ```bash
   echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
   ```

### Manual SSL Configuration

1. Place certificates in `/etc/letsencrypt/live/`
2. Update Nginx configuration if needed
3. Restart Nginx: `docker compose restart nginx`

## Backup and Restore

### Creating Backups

The teardown script offers automatic backup creation:

```bash
./scripts/teardown_prod.sh
```

**Backup Types:**
- **Database**: PostgreSQL dump with custom format
- **Media**: Compressed tar archive
- **Environment**: Configuration files

### Manual Backups

```bash
# Database backup
docker compose exec db pg_dump -U $POSTGRES_USER -d $POSTGRES_DB -Fc > backup/db_$(date +%Y%m%d_%H%M%S).dump

# Media backup
docker compose exec api tar -czf - /app/media > backup/media_$(date +%Y%m%d_%H%M%S).tar.gz
```

### Restoring Backups

```bash
# Database restore
pg_restore -h <host> -U <user> -d <db> backup/db_yyyymmdd.dump

# Media restore
tar -xzf backup/media_yyyymmdd.tar.gz -C /destination/
```

## Troubleshooting

### Common Issues

**Port Conflicts:**
```bash
# Check what's using the port
lsof -i :8000

# Stop conflicting services
sudo systemctl stop apache2  # or nginx
```

**Docker Not Running:**
```bash
# Start Docker
sudo systemctl start docker

# Check Docker status
docker info
```

**Permission Issues:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run:
newgrp docker
```

**SSL Certificate Issues:**
```bash
# Check certificate status
sudo certbot certificates

# Renew certificates
sudo certbot renew

# Test Nginx configuration
docker compose exec nginx nginx -t
```

### Debugging Commands

```bash
# Check service status
./scripts/run_prod.sh status

# View logs
./scripts/run_prod.sh logs

# Check specific service logs
docker compose logs -f api

# Access service shell
docker compose exec api python manage.py shell

# Check health endpoints
curl http://localhost/healthz
curl https://api.example.com/healthz
```

## Security Considerations

### Production Security

1. **Strong Secrets**: All secrets are auto-generated using cryptographically secure methods
2. **Network Isolation**: Internal services are not exposed to the internet
3. **SSL/TLS**: Modern SSL configuration with HSTS
4. **Rate Limiting**: API rate limiting to prevent abuse
5. **Security Headers**: Comprehensive security headers in Nginx
6. **Basic Auth**: Protected monitoring endpoints

### Security Best Practices

1. **Regular Updates**: Keep Docker images and base systems updated
2. **Backup Security**: Store backups securely and encrypt sensitive data
3. **Access Control**: Use strong passwords for monitoring tools
4. **Monitoring**: Set up alerts for security events
5. **Logging**: Monitor logs for suspicious activity

## Performance Optimization

### Development

- **Hot Reload**: Volume mounts for instant code changes
- **Debug Mode**: Full debugging information
- **Local Services**: All services accessible locally

### Production

- **Gunicorn**: Multi-worker WSGI server
- **Nginx**: Efficient reverse proxy with caching
- **Connection Pooling**: Database and Redis connection optimization
- **Static Files**: Optimized static file serving
- **Compression**: Gzip compression for all text content

## Maintenance

### Regular Tasks

**Daily:**
- Check service logs for errors
- Monitor disk space usage

**Weekly:**
- Review security logs
- Check backup status
- Monitor SSL certificate expiration

**Monthly:**
- Update system packages
- Review and rotate logs
- Update Docker images

### Update Procedures

```bash
# Pull latest images
./scripts/run_prod.sh pull

# Restart services
./scripts/run_prod.sh restart

# Run migrations
docker compose exec api python manage.py migrate

# Collect static files
docker compose exec api python manage.py collectstatic --noinput
```

## Support

### Getting Help

1. **Check Logs**: Use the log commands to identify issues
2. **Health Checks**: Verify all services are healthy
3. **Documentation**: Review this guide for common solutions
4. **Community**: Check GitHub issues and discussions

### Reporting Issues

When reporting issues, please include:
- Operating system and version
- Docker and Docker Compose versions
- Complete error messages
- Steps to reproduce
- Environment (development/production)

## Conclusion

The LaunchKit bootstrap system provides a complete, production-ready deployment solution with minimal configuration. It handles the complexity of setting up a full-stack application while maintaining security and performance best practices.

The system is designed to be:
- **Simple**: One command to bootstrap and run
- **Secure**: Production-grade security by default
- **Scalable**: Easy to extend and modify
- **Maintainable**: Clear separation of concerns and documentation

For additional customization or advanced features, refer to the individual component documentation and Docker Compose reference.
