# Production Deployment Guide

This guide provides detailed instructions for deploying LaunchKit to production.

## Prerequisites

- A production server (Ubuntu 20.04 LTS or later recommended)
- Domain name with DNS access
- SSL certificate (Let's Encrypt recommended)
- AWS S3 or DigitalOcean Spaces account (for file storage)

## Deployment Steps

### 1. Server Setup

```bash
# SSH into your production server
ssh user@your-server-ip

# Clone the repository
git clone https://github.com/ShovanSarker/LaunchKit.git
cd LaunchKit

# Run the setup script
sudo ./scripts/setup_server.sh
```

### 2. Domain Configuration

Point your domain's DNS to your server IP by adding the following A records:

```
@       -> your-server-ip
www     -> your-server-ip
api     -> your-server-ip
monitor -> your-server-ip
```

### 3. Environment Setup

The setup script will prompt for:
- Base domain (e.g., example.com)
- Storage provider (AWS S3 or DO Spaces)
- Storage credentials
- Monitoring credentials

Environment files will be created in `templates/env/production/`.

### 4. Storage Setup

#### AWS S3 Setup
1. Create an S3 bucket:
   - Go to AWS S3 Console: https://s3.console.aws.amazon.com
   - Click 'Create bucket'
   - Enter bucket name
   - Select region
   - Uncheck 'Block all public access'
   - Enable versioning (recommended)
   - Click 'Create bucket'

2. Configure bucket policy:
   - Select your bucket
   - Go to 'Permissions' tab
   - Click 'Bucket Policy'
   - Add the following policy:
   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Sid": "PublicReadGetObject",
               "Effect": "Allow",
               "Principal": "*",
               "Action": "s3:GetObject",
               "Resource": "arn:aws:s3:::your-bucket-name/*"
           }
       ]
   }
   ```

3. Configure CORS:
   - Go to 'Permissions' tab
   - Click 'CORS configuration'
   - Add the following configuration:
   ```json
   [
       {
           "AllowedHeaders": ["*"],
           "AllowedMethods": ["GET", "HEAD", "PUT", "POST", "DELETE"],
           "AllowedOrigins": [
               "https://your-domain.com",
               "https://www.your-domain.com",
               "https://api.your-domain.com"
           ],
           "ExposeHeaders": ["ETag"],
           "MaxAgeSeconds": 3600
       }
   ]
   ```

#### DigitalOcean Spaces Setup
1. Create a Space:
   - Go to DigitalOcean Console: https://cloud.digitalocean.com/spaces
   - Click 'Create Space'
   - Enter Space name
   - Select region
   - Choose 'Public' access
   - Click 'Create Space'

2. Configure CORS:
   - Go to your Space
   - Click 'Settings'
   - Under 'CORS Configurations', click 'Add CORS Configuration'
   - Add the following configuration:
   ```json
   {
       "AllowedOrigins": [
           "https://your-domain.com",
           "https://www.your-domain.com",
           "https://api.your-domain.com"
       ],
       "AllowedMethods": ["GET", "HEAD", "PUT", "POST", "DELETE"],
       "AllowedHeaders": ["*"],
       "MaxAgeSeconds": 3600
   }
   ```

3. Configure CDN (optional):
   - Go to your Space
   - Click 'Settings'
   - Under 'CDN', click 'Enable CDN'
   - Choose your CDN endpoint

### 5. SSL Certificate Setup

```bash
# Install Certbot
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# Obtain SSL certificates
sudo certbot --nginx -d your-domain.com -d www.your-domain.com -d api.your-domain.com -d monitor.your-domain.com
```

### 6. Database Setup

```bash
# Access PostgreSQL
sudo -u postgres psql

# Create database and user
CREATE DATABASE launchkit;
CREATE USER launchkit WITH PASSWORD 'your-password';
GRANT ALL PRIVILEGES ON DATABASE launchkit TO launchkit;
```

### 7. Application Deployment

```bash
# Build and start the containers
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

# Run migrations
docker-compose -f docker-compose.prod.yml exec api python manage.py migrate

# Collect static files
docker-compose -f docker-compose.prod.yml exec api python manage.py collectstatic --noinput
```

### 8. Monitoring Setup

1. Access Grafana:
   - URL: `https://monitor.your-domain.com`
   - Use credentials set during setup

2. Set up dashboards for:
   - Application metrics
   - Server metrics
   - Database metrics

### 9. Security Verification

```bash
# Check firewall rules
sudo ufw status

# Verify Nginx configuration
sudo nginx -t

# Test SSL configuration
curl -I https://your-domain.com
```

### 10. Backup Verification

```bash
# Check backup status
sudo systemctl status backup.service

# List available backups
ls -l /backup/
```

### 11. Final Checks

```bash
# Check service status
docker-compose -f docker-compose.prod.yml ps

# Monitor logs
docker-compose -f docker-compose.prod.yml logs -f
```

### 12. Post-Deployment Tasks

1. Set up monitoring alerts in Grafana
2. Configure error reporting in Sentry
3. Set up regular maintenance tasks
4. Document the deployment

## Troubleshooting

### Service Issues

```bash
# Check service logs
docker-compose -f docker-compose.prod.yml logs -f [service-name]

# Restart service
docker-compose -f docker-compose.prod.yml restart [service-name]
```

### Database Issues

```bash
# Check database logs
docker-compose -f docker-compose.prod.yml logs -f db

# Access database
docker-compose -f docker-compose.prod.yml exec db psql -U launchkit
```

### Storage Issues

```bash
# Test storage connection
docker-compose -f docker-compose.prod.yml exec api python manage.py check_storage

# Verify permissions
aws s3 ls s3://your-bucket-name/ --recursive
```

## Rollback Procedure

### Application Rollback

```bash
# Revert to previous version
git checkout <previous-version>
docker-compose -f docker-compose.prod.yml up -d --build
```

### Database Rollback

```bash
# Restore from backup
sudo -u postgres psql launchkit < /backup/launchkit_backup.sql
```

## Scaling

### Horizontal Scaling

```bash
# Scale API service
docker-compose -f docker-compose.prod.yml up -d --scale api=3
```

### Load Balancer Setup

1. Configure Nginx as load balancer
2. Update SSL certificates
3. Set up health checks

## Maintenance

### Regular Updates

```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose -f docker-compose.prod.yml up -d --build
```

### Database Maintenance

```bash
# Vacuum database
docker-compose -f docker-compose.prod.yml exec db vacuumdb -U launchkit -d launchkit
```

### Log Rotation

```bash
# Check log rotation
sudo logrotate -d /etc/logrotate.d/launchkit
```

## Security Best Practices

1. Keep all software updated
2. Regularly rotate credentials
3. Monitor security logs
4. Perform regular security audits
5. Keep backups encrypted
6. Use strong passwords
7. Enable 2FA where possible
8. Regular security scanning

## Monitoring and Alerts

1. Set up Grafana dashboards
2. Configure alert thresholds
3. Set up notification channels
4. Monitor:
   - Server resources
   - Application performance
   - Database metrics
   - Storage usage
   - Security events

## Backup Strategy

### Database Backups
- Daily full backups
- Point-in-time recovery
- Off-site storage

### File Backups
- Regular S3/Spaces backups
- Version control
- Cross-region replication

### Configuration Backups
- Version control
- Documented changes
- Regular verification

## Need Help?

- Check the [troubleshooting guide](#troubleshooting)
- Open an issue on GitHub
- Contact the maintainers 