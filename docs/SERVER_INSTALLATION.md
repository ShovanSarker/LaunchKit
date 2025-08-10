# Server Installation Guide

This guide provides step-by-step instructions for installing LaunchKit on a fresh server using the manual deployment approach.

## Prerequisites

Before starting, ensure you have:

- A server with Ubuntu 20.04+ or similar Linux distribution
- Root access or sudo privileges
- A domain name (optional but recommended for production)
- SSH access to your server

## Step 1: Server Preparation

### 1.1 Connect to Your Server

```bash
# SSH into your server
ssh root@your-server-ip
# or
ssh your-username@your-server-ip
```

### 1.2 Update System Packages

```bash
# Update package lists
sudo apt update

# Upgrade existing packages
sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git unzip software-properties-common
```

### 1.3 Set Up Firewall (Optional but Recommended)

```bash
# Install UFW if not already installed
sudo apt install -y ufw

# Allow SSH (important - don't lock yourself out!)
sudo ufw allow ssh

# Allow HTTP and HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status
```

## Step 2: Install Docker

### 2.1 Install Docker

```bash
# Remove old versions if any
sudo apt remove -y docker docker-engine docker.io containerd runc

# Install prerequisites
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package lists
sudo apt update

# Install Docker
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group (replace 'your-username' with your actual username)
sudo usermod -aG docker $USER

# Verify installation
docker --version
docker compose version
```

### 2.2 Test Docker Installation

```bash
# Test Docker
sudo docker run hello-world

# If you added yourself to docker group, you may need to log out and back in
# or run this command to apply group changes:
newgrp docker
```

## Step 3: Install LaunchKit

### 3.1 Clone the Repository

```bash
# Navigate to a suitable directory
cd /opt

# Clone the repository
sudo git clone https://github.com/YOUR_USERNAME/LaunchKit.git
# or if you have your own fork:
# sudo git clone https://github.com/your-username/LaunchKit.git

# Change ownership to your user (replace 'your-username' with your actual username)
sudo chown -R $USER:$USER LaunchKit

# Navigate to the project directory
cd LaunchKit
```

### 3.2 Run the Server Setup Script

```bash
# Make the script executable
chmod +x scripts/setup_server.sh

# Run the server setup script
sudo ./scripts/setup_server.sh
```

This script will:
- Install additional system dependencies
- Configure security settings (Fail2ban, UFW)
- Create environment templates
- Set up the run scripts directory structure

## Step 4: Configure Environment Files

### 4.1 Create Environment Files

```bash
# Create API environment file
cp templates/env/production/api.env.template api/.env

# Create Frontend environment file
cp templates/env/production/app.env.template app/.env.local

# Create Docker environment file
cp templates/env/production/docker.env.template docker/.env
```

### 4.2 Configure API Environment (`api/.env`)

Edit the API environment file:

```bash
nano api/.env
```

Update the following key settings:

```bash
# =============================================================================
# PROJECT SETTINGS
# =============================================================================
PROJECT_NAME=YourProjectName
PROJECT_SLUG=yourproject

# =============================================================================
# DJANGO SETTINGS
# =============================================================================
DJANGO_ENV=production
DEBUG=False

# Generate a secure secret key (run this command and copy the output):
# openssl rand -base64 32
DJANGO_SECRET_KEY=your-generated-secret-key-here

# Add your domain names (comma-separated)
ALLOWED_HOSTS=your-domain.com,api.your-domain.com,www.your-domain.com,your-server-ip

# Add your frontend URLs (comma-separated)
CSRF_TRUSTED_ORIGINS=https://your-domain.com,https://api.your-domain.com

# =============================================================================
# DATABASE SETTINGS
# =============================================================================
POSTGRES_DB=yourproject
POSTGRES_USER=yourproject
POSTGRES_PASSWORD=your-secure-db-password-here
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# =============================================================================
# EMAIL SETTINGS (PRODUCTION)
# =============================================================================
# For SendGrid (recommended):
EMAIL_BACKEND=sendgrid_backend.SendgridBackend
SENDGRID_API_KEY=your-sendgrid-api-key-here
SENDGRID_FROM_EMAIL=your-email@your-domain.com

# =============================================================================
# FRONTEND URL
# =============================================================================
FRONTEND_URL=https://your-domain.com
```

### 4.3 Configure Frontend Environment (`app/.env.local`)

Edit the frontend environment file:

```bash
nano app/.env.local
```

Update the following key settings:

```bash
# =============================================================================
# PROJECT INFORMATION
# =============================================================================
NEXT_PUBLIC_PROJECT_NAME=YourProjectName
NEXT_PUBLIC_PROJECT_SLUG=yourproject

# =============================================================================
# API SETTINGS
# =============================================================================
NEXT_PUBLIC_API_URL=https://api.your-domain.com

# =============================================================================
# AUTHENTICATION SETTINGS
# =============================================================================
NEXTAUTH_URL=https://your-domain.com

# Generate a secure secret (run this command and copy the output):
# openssl rand -base64 32
NEXTAUTH_SECRET=your-generated-nextauth-secret-here
```

### 4.4 Configure Docker Environment (`docker/.env`)

Edit the Docker environment file:

```bash
nano docker/.env
```

Update the following key settings:

```bash
# =============================================================================
# PROJECT SETTINGS
# =============================================================================
PROJECT_NAME=YourProjectName
PROJECT_SLUG=yourproject

# =============================================================================
# DOMAIN SETTINGS
# =============================================================================
DOMAIN=your-domain.com
EMAIL=admin@your-domain.com

# =============================================================================
# DATABASE SETTINGS
# =============================================================================
POSTGRES_DB=yourproject
POSTGRES_USER=yourproject
POSTGRES_PASSWORD=your-secure-db-password-here

# =============================================================================
# RABBITMQ SETTINGS
# =============================================================================
RABBITMQ_DEFAULT_USER=yourproject
RABBITMQ_DEFAULT_PASS=your-secure-rabbitmq-password-here
RABBITMQ_DEFAULT_VHOST=yourproject

# =============================================================================
# MONITORING SETTINGS
# =============================================================================
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=your-secure-grafana-password-here
```

## Step 5: Configure DNS (If Using Domain)

### 5.1 Set Up DNS Records

If you have a domain name, configure these DNS records:

```
A     your-domain.com        → Your server IP
A     api.your-domain.com    → Your server IP
A     monitor.your-domain.com → Your server IP
```

### 5.2 Verify DNS Configuration

```bash
# Check if DNS records are properly set
dig your-domain.com
dig api.your-domain.com
dig monitor.your-domain.com
```

## Step 6: Start Production Services

### 6.1 Start All Services

```bash
# Start all production services
./run/production/run_prod_all.sh
```

### 6.2 Verify Services Are Running

```bash
# Check service status
./run/production/run_prod_all.sh status

# View logs
./run/production/run_prod_all.sh logs
```

## Step 7: Post-Deployment Tasks

### 7.1 Run Database Migrations

```bash
# Run Django migrations
./run/production/run_backend.sh migrate
```

### 7.2 Create Superuser

```bash
# Create admin user
./run/production/run_backend.sh createsuperuser
```

### 7.3 Collect Static Files

```bash
# Collect static files
./run/production/run_backend.sh collectstatic
```

## Step 8: SSL Configuration (Recommended)

### 8.1 Install Certbot

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx
```

### 8.2 Get SSL Certificates

```bash
# Get SSL certificates for your domains
sudo certbot --nginx -d your-domain.com -d api.your-domain.com -d monitor.your-domain.com

# Set up auto-renewal
sudo crontab -e
# Add this line: 0 12 * * * /usr/bin/certbot renew --quiet
```

## Step 9: Verify Installation

### 9.1 Health Check

```bash
# Run health check
./run/production/run_prod_all.sh health
```

### 9.2 Test Access

Access your application:

- **Frontend**: https://your-domain.com (or http://your-server-ip:3000)
- **Backend API**: https://api.your-domain.com (or http://your-server-ip:8000)
- **API Documentation**: https://api.your-domain.com/api/docs/
- **Admin Interface**: https://api.your-domain.com/admin
- **Monitoring**: https://monitor.your-domain.com (or http://your-server-ip:3001)

### 9.3 Check Service Logs

```bash
# View all logs
./run/production/run_prod_all.sh logs

# View specific service logs
./run/production/run_backend.sh logs
./run/production/run_frontend.sh logs
./run/production/run_nginx.sh logs
```

## Step 10: Security Hardening

### 10.1 Configure Firewall

```bash
# Check firewall status
sudo ufw status

# If not enabled, enable it
sudo ufw enable
```

### 10.2 Set Up Fail2ban

```bash
# Check Fail2ban status
sudo fail2ban-client status

# View banned IPs
sudo fail2ban-client status sshd
```

### 10.3 Regular Security Updates

```bash
# Set up automatic security updates
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

## Troubleshooting

### Common Issues

1. **Docker not running**:
   ```bash
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

2. **Port conflicts**:
   ```bash
   # Check what's using the port
   sudo lsof -i :8000
   sudo lsof -i :3000
   ```

3. **Service won't start**:
   ```bash
   # Check service status
   ./run/production/run_prod_all.sh status
   
   # View logs
   ./run/production/run_prod_all.sh logs
   ```

4. **Database connection issues**:
   ```bash
   # Check database status
   docker ps | grep postgres
   
   # Test database connection
   docker exec -it launchkit_postgres psql -U yourproject -d yourproject -c "SELECT 1;"
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

## Maintenance

### Regular Tasks

1. **Daily**:
   - Check service logs for errors
   - Monitor disk space

2. **Weekly**:
   - Review security logs
   - Check backup status

3. **Monthly**:
   - Update system packages
   - Review SSL certificate expiration

### Backup Strategy

```bash
# Create backup script
sudo nano /root/backup_launchkit.sh
```

Add this content:

```bash
#!/bin/bash
BACKUP_DIR="/var/backups/launchkit"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Backup database
docker exec launchkit_postgres pg_dump -U yourproject yourproject > $BACKUP_DIR/db_backup_$DATE.sql

# Backup environment files
tar -czf $BACKUP_DIR/env_backup_$DATE.tar.gz /opt/LaunchKit/api/.env /opt/LaunchKit/app/.env.local /opt/LaunchKit/docker/.env

# Keep only last 30 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
```

Make it executable and add to crontab:

```bash
sudo chmod +x /root/backup_launchkit.sh
echo "0 2 * * * /root/backup_launchkit.sh" | sudo crontab -
```

## Next Steps

After successful installation:

1. **Explore the API**: Visit your API documentation
2. **Create content**: Add your first superuser and test the admin interface
3. **Customize**: Modify the frontend and backend to match your needs
4. **Monitor**: Set up monitoring alerts in Grafana
5. **Scale**: Consider load balancing and horizontal scaling as needed

## Support

If you encounter issues:

1. Check the [troubleshooting section](#troubleshooting)
2. Review the [Production Guide](PRODUCTION.md)
3. Check service logs for error messages
4. Ensure all environment variables are properly configured

## Additional Resources

- [Production Guide](PRODUCTION.md) - Detailed production deployment
- [Development Guide](DEVELOPMENT.md) - Local development setup
- [API Handling Guide](../API_HANDLING_GUIDE.md) - API development guidelines
- [Celery Setup Guide](../celery-setup.md) - Background task configuration
