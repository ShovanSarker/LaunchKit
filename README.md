# LaunchKit

```
 _                            _     _   ___ _   
| |                          | |   | | / (_) |  
| |     __ _ _   _ _ __   ___| |__ | |/ / _| |_ 
| |    / _` | | | | '_ \ / __| '_ \|    \| | __|
| |___| (_| |_| |_| | | | (__| | | | |\  \ | |_ 
\_____/\__,_|\__,_|_| |_|\___|_| |_\_| \_/_|\__| 
```

Full‑stack Django + DRF + Celery + RabbitMQ + Redis + Next.js boilerplate. Everything ships in a single repository, with manual deployment scripts for granular control.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Django](https://img.shields.io/badge/Django-4.2-green.svg)](https://www.djangoproject.com/)
[![Next.js](https://img.shields.io/badge/Next.js-14.1.0-black.svg)](https://nextjs.org/)
[![Docker](https://img.shields.io/badge/Docker-20.10+-blue.svg)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://www.python.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.0+-blue.svg)](https://www.typescriptlang.org/)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.0-4baaaa.svg)](CODE_OF_CONDUCT.md)

## Quick Links

- [Bootstrap System Guide](docs/launchkit-bootstrap.md) - Complete bootstrap system documentation
- [Development Guide](docs/DEVELOPMENT.md) - Setup and development workflow
- [Production Guide](docs/PRODUCTION.md) - Deployment and production setup
- [Contributing Guide](CONTRIBUTING.md) - How to contribute to LaunchKit
- [Code of Conduct](CODE_OF_CONDUCT.md) - Community guidelines
- [Changelog](CHANGELOG.md) - Project version history

## Getting Started

### Option 1: Fork and Clone (Recommended)

1. **Fork the Repository**
   - Click the "Fork" button in the top-right corner of this repository
   - This creates your own copy of LaunchKit in your GitHub account

2. **Clone Your Fork**
   ```bash
   # Replace YOUR_USERNAME with your GitHub username
   git clone https://github.com/YOUR_USERNAME/LaunchKit.git
   cd LaunchKit
   ```

3. **Add Upstream Remote**
   ```bash
   git remote add upstream https://github.com/ShovanSarker/LaunchKit.git
   ```

4. **Keep Your Fork Updated**
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

### Option 2: Use as Template

1. **Create New Repository**
   - Click "Use this template" button on GitHub
   - Choose a name for your new repository
   - Select public or private visibility

2. **Clone Your New Repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
   cd YOUR_REPO_NAME
   ```

## Quick Start

### One-Command Bootstrap & Run

LaunchKit now features a streamlined bootstrap system for easy deployment:

1. **Bootstrap Your Project**
   ```bash
   # Interactive setup for development or production
   ./scripts/bootstrap.sh
   ```

2. **Development Environment**
   ```bash
   # Start complete development stack
   ./scripts/run_dev.sh
   ```

3. **Production Environment**
   ```bash
   # Deploy full production stack
   ./scripts/run_prod.sh
   ```

4. **Access Your Application**
   - **Development**: 
     - Frontend: http://localhost:3000
     - Backend API: http://localhost:8000
     - API Documentation: http://localhost:8000/api/docs/
   - **Production**: 
     - Frontend: https://your-app-domain.com
     - Backend API: https://your-api-domain.com

### Manual Setup (Legacy)

For manual deployment with individual scripts:

1. **Initial Setup**
   ```bash
   # Run the setup script
   ./scripts/setup_development.sh
   ```

2. **Start All Services**
   ```bash
   # Start backend, database, Redis, RabbitMQ
   ./run/development/run_dev_all.sh
   ```

3. **Start Frontend**
   ```bash
   # Start Next.js development server
   cd app && npm run dev
   ```

4. **Access the Application**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:8000
   - API Documentation: http://localhost:8000/api/docs/
   - Admin Interface: http://localhost:8000/admin

### Production Environment

1. **Server Setup**
   ```bash
   # Run the production setup script
   ./scripts/setup_server.sh
   ```

2. **Start All Services**
   ```bash
   # Start all production services
   ./run/production/run_prod_all.sh
   ```

3. **Post-Deployment Tasks**
   ```bash
   # Run migrations
   ./run/production/run_backend.sh migrate
   
   # Create superuser
   ./run/production/run_backend.sh createsuperuser
   ```

## Manual Service Management

### Development Services

```bash
# Individual service control
./run/development/run_backend.sh [start|stop|restart|status|logs]
./run/development/run_worker.sh [start|stop|restart|status|logs]
./run/development/run_scheduler.sh [start|stop|restart|status|logs]
./run/development/run_redis.sh [start|stop|restart|status|logs|cli]
./run/development/run_rabbitmq.sh [start|stop|restart|status|logs|ui]

# All services at once
./run/development/run_dev_all.sh [start|stop|restart|status|logs]
```

### Production Services

```bash
# Individual service control
./run/production/run_backend.sh [start|stop|restart|status|logs|migrate|collectstatic|createsuperuser]
./run/production/run_frontend.sh [start|stop|restart|status|logs|build]
./run/production/run_nginx.sh [start|stop|restart|status|logs|test|reload]
./run/production/run_monitoring.sh [start|stop|restart|status|logs|grafana|prometheus]

# All services at once
./run/production/run_prod_all.sh [start|stop|restart|status|logs|health]
```

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Backend       │    │   Database      │
│   (Next.js)     │◄──►│   (Django/DRF)  │◄──►│   (PostgreSQL)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Nginx         │    │   Celery        │    │   Redis         │
│   (Reverse      │    │   (Background   │    │   (Cache/       │
│    Proxy)       │    │    Tasks)       │    │    Sessions)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Monitoring    │    │   RabbitMQ      │    │   Object        │
│   (Prometheus   │    │   (Message      │    │   Storage       │
│    + Grafana)   │    │    Broker)      │    │   (S3/Spaces)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Features

### Backend (Django + DRF)
- **Authentication**: JWT-based authentication with refresh tokens
- **Email System**: Django Email Admin with email logging and preview
- **API Documentation**: Auto-generated Swagger/OpenAPI documentation
- **Background Tasks**: Celery with RabbitMQ for async task processing
- **Caching**: Redis for session storage and caching
- **Database**: PostgreSQL with Django ORM
- **Admin Interface**: Customizable Django admin with email preview

### Frontend (Next.js)
- **Modern UI**: Built with Next.js 14, TypeScript, and Tailwind CSS
- **Authentication**: JWT-based authentication with automatic token refresh
- **Responsive Design**: Mobile-first responsive design
- **Type Safety**: Full TypeScript support
- **API Integration**: Axios-based API client with interceptors

### Infrastructure
- **Containerization**: Docker and Docker Compose for easy deployment
- **Reverse Proxy**: Nginx with SSL termination and load balancing
- **Monitoring**: Prometheus and Grafana for metrics and alerting
- **Security**: UFW firewall, Fail2ban, and security headers
- **SSL**: Automatic SSL certificate management with Let's Encrypt
- **Backup**: Automated database and file backups

### Development Tools
- **Hot Reload**: Fast development with hot reloading
- **Type Checking**: TypeScript and Python type checking
- **Linting**: ESLint and Prettier for code quality
- **Testing**: Jest and Django testing frameworks
- **Debugging**: Comprehensive logging and debugging tools

## Environment Setup

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

## Service URLs

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

## Troubleshooting

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

### Debugging Commands

```bash
# Check service status
./run/development/run_backend.sh status

# View service logs
./run/development/run_backend.sh logs

# Check Docker containers
docker ps
docker logs <container_name>

# Health check (production)
./run/production/run_prod_all.sh health
```

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on how to:

- Report bugs
- Suggest new features
- Submit pull requests
- Follow our coding standards

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Documentation**: Check `README.md` and `docs/` directory
- **Issues**: Create an issue on GitHub
- **Discussions**: Join our community discussions
- **Email**: Contact us at support@launchkit.dev

## Acknowledgments

- **Django**: The web framework for perfectionists with deadlines
- **Next.js**: The React framework for production
- **Docker**: Containerization platform
- **Celery**: Distributed task queue
- **PostgreSQL**: Advanced open source database
- **Redis**: In-memory data structure store
- **RabbitMQ**: Message broker
- **Nginx**: Web server and reverse proxy
- **Prometheus**: Monitoring system and time series database
- **Grafana**: Analytics and monitoring solution

---

**Built with ❤️ by Shovan Sarker** 