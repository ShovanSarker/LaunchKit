# Production Guide

This guide covers deploying LaunchKit to production using the manual deployment approach.

## Prerequisites

Before deploying to production, ensure you have:

- A server with Ubuntu 20.04+ or similar Linux distribution
- Root access or sudo privileges
- A domain name (optional but recommended)
- SSL certificates (recommended for production)

## Server Setup

### 1. Initial Server Preparation

SSH into your server and run the production setup script:

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/LaunchKit.git
cd LaunchKit

# Run the production setup script
sudo ./scripts/setup_server.sh
```

This script will:
- Install system dependencies (Docker, Nginx, etc.)
- Configure firewall and security settings
- Create environment templates
- Set up the run scripts directory structure

### 2. Configure Environment Files

Copy and configure the production environment templates:

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

### 3. Configure DNS Records

Set up DNS records pointing to your server:

```
A     your-domain.com        → Your server IP
A     api.your-domain.com    → Your server IP
A     monitor.your-domain.com → Your server IP
```

### 4. Start Production Services

Start all production services:

```bash
# Start all production services
./run/production/run_prod_all.sh
```

### 5. Post-Deployment Tasks

Run essential post-deployment tasks:

```bash
# Run database migrations
./run/production/run_backend.sh migrate

# Create superuser
./run/production/run_backend.sh createsuperuser

# Collect static files
./run/production/run_backend.sh collectstatic
```

## Manual Service Management

### Individual Service Control

You can manage individual services:

```bash
# Backend API
./run/production/run_backend.sh [start|stop|restart|status|logs|migrate|collectstatic|createsuperuser]

# Frontend
./run/production/run_frontend.sh [start|stop|restart|status|logs|build]

# Nginx
./run/production/run_nginx.sh [start|stop|restart|status|logs|test|reload]

# Monitoring
./run/production/run_monitoring.sh [start|stop|restart|status|logs|grafana|prometheus]

# Worker, Scheduler, Redis, RabbitMQ
./run/production/run_worker.sh [start|stop|restart|status|logs]
./run/production/run_scheduler.sh [start|stop|restart|status|logs]
./run/production/run_redis.sh [start|stop|restart|status|logs|cli]
./run/production/run_rabbitmq.sh [start|stop|restart|status|logs|ui]
```

### All Services at Once

```bash
# Start all services
./run/production/run_prod_all.sh

# Stop all services
./run/production/run_prod_all.sh stop

# Restart all services
./run/production/run_prod_all.sh restart

# Health check
./run/production/run_prod_all.sh health

# View logs
./run/production/run_prod_all.sh logs
```

## Environment Configuration

### API Environment (`api/.env`)

Key production settings:

```bash
# Project Settings
PROJECT_NAME=YourProjectName
PROJECT_SLUG=yourproject

# Django Settings
DJANGO_ENV=production
DEBUG=False
DJANGO_SECRET_KEY=your-very-secure-secret-key
ALLOWED_HOSTS=your-domain.com,api.your-domain.com,www.your-domain.com
CSRF_TRUSTED_ORIGINS=https://your-domain.com,https://api.your-domain.com

# Database
POSTGRES_DB=yourproject
POSTGRES_USER=yourproject
POSTGRES_PASSWORD=your-secure-db-password
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# Email (Production)
EMAIL_BACKEND=sendgrid_backend.SendgridBackend
SENDGRID_API_KEY=your-sendgrid-api-key
SENDGRID_FROM_EMAIL=your-email@your-domain.com

# Frontend URL
FRONTEND_URL=https://your-domain.com
```

### Frontend Environment (`app/.env.local`)

Key production settings:

```bash
# Project Information
NEXT_PUBLIC_PROJECT_NAME=YourProjectName
NEXT_PUBLIC_PROJECT_SLUG=yourproject

# API Settings
NEXT_PUBLIC_API_URL=https://api.your-domain.com

# Authentication
NEXTAUTH_URL=https://your-domain.com
NEXTAUTH_SECRET=your-nextauth-secret

# Feature Flags
NEXT_PUBLIC_FEATURE_REGISTRATION_ENABLED=true
NEXT_PUBLIC_FEATURE_SOCIAL_LOGIN_ENABLED=false
```

### Docker Environment (`docker/.env`)

Key production settings:

```bash
# Project Settings
PROJECT_NAME=YourProjectName
PROJECT_SLUG=yourproject

# Domain
DOMAIN=your-domain.com
EMAIL=admin@your-domain.com

# Database
POSTGRES_DB=yourproject
POSTGRES_USER=yourproject
POSTGRES_PASSWORD=your-secure-db-password

# RabbitMQ
RABBITMQ_DEFAULT_USER=yourproject
RABBITMQ_DEFAULT_PASS=your-rabbitmq-password
RABBITMQ_DEFAULT_VHOST=yourproject

# Monitoring
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=your-secure-grafana-password
```

## SSL Configuration

### Automatic SSL with Let's Encrypt

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificates
sudo certbot --nginx -d your-domain.com -d api.your-domain.com -d monitor.your-domain.com

# Set up auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### Manual SSL Configuration

If you have your own SSL certificates:

1. Place certificates in `/etc/ssl/certs/`
2. Update Nginx configuration
3. Restart Nginx: `./run/production/run_nginx.sh restart`

## Monitoring and Logging

### Health Checks

```bash
# Check overall health
./run/production/run_prod_all.sh health

# Check specific services
./run/production/run_backend.sh status
./run/production/run_frontend.sh status
./run/production/run_nginx.sh status
```

### Monitoring Dashboard

Access monitoring at:
- **Grafana**: https://monitor.your-domain.com
- **Prometheus**: http://your-server-ip:9090

### Log Management

```bash
# View all logs
./run/production/run_prod_all.sh logs

# View specific service logs
./run/production/run_backend.sh logs
./run/production/run_nginx.sh logs

# Follow logs in real-time
./run/production/run_backend.sh logs | tail -f
```

## Backup Strategy

### Database Backups

```bash
# Create backup script
cat > /root/backup_db.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/launchkit"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Backup database
docker exec launchkit_postgres pg_dump -U yourproject yourproject > $BACKUP_DIR/db_backup_$DATE.sql

# Keep only last 30 days of backups
find $BACKUP_DIR -name "db_backup_*.sql" -mtime +30 -delete
EOF

chmod +x /root/backup_db.sh

# Add to crontab
echo "0 2 * * * /root/backup_db.sh" | crontab -
```

### File Backups

```bash
# Backup important files
tar -czf /var/backups/launchkit/files_backup_$(date +%Y%m%d_%H%M%S).tar.gz \
  /opt/launchkit/api/.env \
  /opt/launchkit/app/.env.local \
  /opt/launchkit/docker/.env
```

## Security Hardening

### Firewall Configuration

The setup script configures UFW, but you can customize:

```bash
# Allow SSH
sudo ufw allow ssh

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable
```

### Fail2ban Configuration

```bash
# Check Fail2ban status
sudo fail2ban-client status

# View banned IPs
sudo fail2ban-client status sshd
```

### Security Headers

Nginx is configured with security headers, but you can customize:

```bash
# Edit Nginx configuration
sudo nano /etc/nginx/sites-available/launchkit

# Test configuration
./run/production/run_nginx.sh test

# Reload configuration
./run/production/run_nginx.sh reload
```

## Performance Optimization

### Database Optimization

```bash
# Check database performance
docker exec -it launchkit_postgres psql -U yourproject -d yourproject -c "SELECT * FROM pg_stat_activity;"
```

### Nginx Optimization

```bash
# Check Nginx configuration
./run/production/run_nginx.sh test

# Monitor Nginx performance
docker exec launchkit_nginx nginx -V
```

### Monitoring Alerts

Set up monitoring alerts in Grafana:
1. Access Grafana dashboard
2. Create alert rules for critical metrics
3. Configure notification channels (email, Slack, etc.)

## Troubleshooting

### Common Issues

1. **Service won't start**:
   ```bash
   # Check service status
   ./run/production/run_backend.sh status
   
   # View logs
   ./run/production/run_backend.sh logs
   
   # Check Docker
   docker ps
   docker logs <container_name>
   ```

2. **Database connection issues**:
   ```bash
   # Check database status
   ./run/production/run_backend.sh status
   
   # Test database connection
   docker exec -it launchkit_postgres psql -U yourproject -d yourproject -c "SELECT 1;"
   ```

3. **SSL certificate issues**:
   ```bash
   # Check certificate status
   sudo certbot certificates
   
   # Renew certificates
   sudo certbot renew
   ```

### Debugging Commands

```bash
# Check all services
./run/production/run_prod_all.sh status

# View all logs
./run/production/run_prod_all.sh logs

# Health check
./run/production/run_prod_all.sh health

# Check system resources
docker stats
df -h
free -h
```

### Emergency Procedures

```bash
# Stop all services
./run/production/run_prod_all.sh stop

# Restart all services
./run/production/run_prod_all.sh restart

# Rollback to previous version
git checkout <previous-commit>
./run/production/run_prod_all.sh restart
```

## Maintenance

### Regular Maintenance Tasks

1. **Weekly**:
   - Check service logs for errors
   - Monitor disk space usage
   - Review security logs

2. **Monthly**:
   - Update system packages
   - Review and rotate logs
   - Check SSL certificate expiration

3. **Quarterly**:
   - Review security settings
   - Update application dependencies
   - Test backup and restore procedures

### Update Procedures

```bash
# Pull latest changes
git pull origin main

# Rebuild containers
cd docker && docker compose build --no-cache

# Restart services
./run/production/run_prod_all.sh restart

# Run migrations
./run/production/run_backend.sh migrate
```

## Additional Resources

- [Development Guide](DEVELOPMENT.md) - Local development setup
- [Manual Setup Guide](../run/SETUP_GUIDE.md) - Detailed manual deployment guide
- [API Handling Guide](../API_HANDLING_GUIDE.md) - API development guidelines
- [Celery Setup Guide](../celery-setup.md) - Background task configuration 