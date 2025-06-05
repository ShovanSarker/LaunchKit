# Production Deployment Guide

This guide provides detailed instructions for deploying LaunchKit to production.

## Prerequisites

- A production server (Ubuntu 20.04 LTS or later recommended)
- Domain name with DNS access
- SSL certificate (Let's Encrypt recommended)
- Storage provider account (AWS S3 or DigitalOcean Spaces)

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

Important: All subdomains must be properly configured in your DNS settings before running the SSL certificate setup. The following subdomains are required:
- www.your-domain.com
- api.your-domain.com
- monitor.your-domain.com

To verify DNS configuration:
```bash
# Check if DNS records are properly set
dig www.your-domain.com
dig api.your-domain.com
dig monitor.your-domain.com

# Wait for DNS propagation (can take up to 48 hours, but usually much faster)
```

Note: SSL certificate setup will fail if any of these subdomains are not properly configured in DNS.

### 3. Environment Setup

Run the environment setup script:

```bash
./scripts/setup_env.sh
```

The script will prompt for:
- Base domain (e.g., example.com)
- Email for Let's Encrypt
- Project slug (e.g., launchkit)
- Database password
- RabbitMQ password
- SendGrid settings:
  - API Key
  - Verified sender email
  - Sender name
- Storage provider (AWS S3 or DO Spaces)
- Storage credentials

The script will:
1. Generate secure random strings for secrets
2. Create environment files with proper formatting
3. Configure storage settings based on your provider choice
4. Set up SendGrid email configuration

### 4. Email Setup (SendGrid)

1. Create a SendGrid account:
   - Go to SendGrid: https://signup.sendgrid.com/
   - Complete the signup process
   - Verify your domain

2. Create an API Key:
   - Go to Settings > API Keys
   - Click 'Create API Key'
   - Choose 'Full Access' or 'Restricted Access' with Mail Send permissions
   - Copy the API key

3. Verify your sender email:
   - Go to Settings > Sender Authentication
   - Click 'Verify a Single Sender'
   - Fill in the required information
   - Click 'Create'

4. Configure domain authentication (recommended):
   - Go to Settings > Sender Authentication
   - Click 'Authenticate Your Domain'
   - Follow the DNS configuration steps
   - Wait for DNS propagation

### 4. Storage Setup

#### DigitalOcean Spaces Setup (Recommended)
1. Create Spaces:
   - Go to DigitalOcean Console: https://cloud.digitalocean.com/spaces
   - Click 'Create Space'
   - Create two spaces:
     - `launchkit-static` for static files
     - `launchkit-media` for media files
   - Select region (e.g., nyc3)
   - Choose 'Public' access
   - Click 'Create Space'

2. Configure CORS for each Space:
   - Go to your Space
   - Click 'Settings'
   - Under 'CORS Configurations', click 'Add CORS Configuration'
   - Add the following configuration:
   ```json
   {
       "AllowedOrigins": [
           "https://lk.zero-zero-nine.com",
           "https://www.lk.zero-zero-nine.com",
           "https://api.lk.zero-zero-nine.com"
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

4. Get API Keys:
   - Go to API > Tokens/Keys
   - Generate new Spaces access key
   - Save both the key and secret

#### AWS S3 Setup (Alternative)
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

### 5. SSL Certificate Setup

```bash
# Install Certbot
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# Obtain SSL certificates
sudo certbot --nginx -d your-domain.com -d www.your-domain.com -d api.your-domain.com -d monitor.your-domain.com --email your-email@example.com --agree-tos --non-interactive
```

### 6. Database Setup

1. Create docker-compose.prod.yml:
```bash
# Create the production docker-compose file
cp docker-compose.yml docker-compose.prod.yml
```

2. Update database configuration in docker-compose.prod.yml:
```yaml
services:
  db:
    image: postgres:13
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    environment:
      - POSTGRES_DB=${DB_NAME}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    networks:
      - app-network

volumes:
  postgres_data:

networks:
  app-network:
    driver: bridge
```

3. Start the database:
```bash
# Start the database container
docker-compose -f docker-compose.prod.yml up -d db

# Wait for database to be ready
sleep 10

# Verify database connection
docker-compose -f docker-compose.prod.yml exec db psql -U ${DB_USER} -d ${DB_NAME} -c "\l"
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

# Access database (replace 'your-project-slug' with your actual project slug)
docker-compose -f docker-compose.prod.yml exec db psql -U your-project-slug
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
# Restore from backup (replace 'your-project-slug' with your actual project slug)
sudo -u postgres psql your-project-slug < /backup/your-project-slug_backup.sql
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
# Vacuum database (replace 'your-project-slug' with your actual project slug)
docker-compose -f docker-compose.prod.yml exec db vacuumdb -U your-project-slug -d your-project-slug
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